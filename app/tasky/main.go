package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

type user struct {
	ID       primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Email    string             `bson:"email" json:"email"`
	Password string             `bson:"password" json:"-"`
}

type todo struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID `bson:"user_id" json:"user_id"`
	Title     string             `bson:"title" json:"title"`
	Done      bool               `bson:"done" json:"done"`
	CreatedAt time.Time          `bson:"created_at" json:"created_at"`
}

type server struct {
	db        *mongo.Database
	jwtSecret []byte
}

func main() {
	_ = godotenv.Load(".env")

	mongoURL := os.Getenv("MONGODB_URL")
	secret := os.Getenv("SECRET_KEY")
	if mongoURL == "" || secret == "" {
		log.Fatal("MONGODB_URL and SECRET_KEY are required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURL))
	if err != nil {
		log.Fatal(err)
	}

	if err := client.Ping(ctx, nil); err != nil {
		log.Fatal(err)
	}

	s := &server{db: client.Database("go-mongodb"), jwtSecret: []byte(secret)}

	r := gin.Default()
	r.LoadHTMLGlob("assets/*.html")
	r.Static("/assets", "./assets")
	r.GET("/", s.index)
	r.GET("/todo", s.todoPage)
	r.GET("/healthz", s.health)
	r.POST("/signup", s.signup)
	r.POST("/login", s.login)

	auth := r.Group("/todos")
	auth.Use(s.auth())
	auth.GET("", s.listTodos)
	auth.POST("", s.createTodo)
	auth.PATCH("/:id", s.updateTodo)
	auth.DELETE("/:id", s.deleteTodo)

	if err := r.Run(":8080"); err != nil {
		log.Fatal(err)
	}
}


func (s *server) index(c *gin.Context) {
	c.HTML(http.StatusOK, "login.html", gin.H{"title": "Tasky Login"})
}

func (s *server) todoPage(c *gin.Context) {
	c.HTML(http.StatusOK, "todo.html", gin.H{"title": "Tasky Todo"})
}

func (s *server) health(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 3*time.Second)
	defer cancel()

	if err := s.db.Client().Ping(ctx, nil); err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"status": "degraded"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *server) signup(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required,min=8"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "hash failed"})
		return
	}

	res, err := s.db.Collection("users").InsertOne(c.Request.Context(), user{Email: req.Email, Password: string(hash)})
	if mongo.IsDuplicateKeyError(err) {
		c.JSON(http.StatusConflict, gin.H{"error": "user exists"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "insert failed"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": res.InsertedID})
}

func (s *server) login(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var u user
	if err := s.db.Collection("users").FindOne(c.Request.Context(), bson.M{"email": req.Email}).Decode(&u); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": u.ID.Hex(),
		"exp": time.Now().Add(8 * time.Hour).Unix(),
	})

	signed, err := token.SignedString(s.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "token failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": signed})
}

func (s *server) auth() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenText := c.GetHeader("Authorization")
		if len(tokenText) > 7 && tokenText[:7] == "Bearer " {
			tokenText = tokenText[7:]
		}

		claims := jwt.MapClaims{}
		token, err := jwt.ParseWithClaims(tokenText, claims, func(token *jwt.Token) (interface{}, error) {
			return s.jwtSecret, nil
		})
		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			return
		}

		sub, ok := claims["sub"].(string)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "bad subject"})
			return
		}

		userID, err := primitive.ObjectIDFromHex(sub)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "bad subject"})
			return
		}

		c.Set("user_id", userID)
		c.Next()
	}
}

func (s *server) listTodos(c *gin.Context) {
	userID := c.MustGet("user_id").(primitive.ObjectID)
	cur, err := s.db.Collection("todos").Find(c.Request.Context(), bson.M{"user_id": userID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	defer cur.Close(c.Request.Context())

	items := []todo{}
	if err := cur.All(c.Request.Context(), &items); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "decode failed"})
		return
	}

	c.JSON(http.StatusOK, items)
}

func (s *server) createTodo(c *gin.Context) {
	userID := c.MustGet("user_id").(primitive.ObjectID)

	var req struct {
		Title string `json:"title" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item := todo{UserID: userID, Title: req.Title, Done: false, CreatedAt: time.Now().UTC()}
	res, err := s.db.Collection("todos").InsertOne(c.Request.Context(), item)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "insert failed"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": res.InsertedID})
}

func (s *server) updateTodo(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "bad id"})
		return
	}

	var req struct {
		Title *string `json:"title"`
		Done  *bool   `json:"done"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	set := bson.M{}
	if req.Title != nil {
		set["title"] = *req.Title
	}
	if req.Done != nil {
		set["done"] = *req.Done
	}

	_, err = s.db.Collection("todos").UpdateOne(c.Request.Context(), bson.M{"_id": id}, bson.M{"$set": set})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
		return
	}

	c.Status(http.StatusNoContent)
}

func (s *server) deleteTodo(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "bad id"})
		return
	}

	_, err = s.db.Collection("todos").DeleteOne(c.Request.Context(), bson.M{"_id": id})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "delete failed"})
		return
	}

	c.Status(http.StatusNoContent)
}
