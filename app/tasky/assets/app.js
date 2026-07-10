const tokenKey = "taskyToken";
const message = document.getElementById("message");

function setMessage(text, isError = false) {
  if (!message) return;
  message.textContent = text || "";
  message.className = isError ? "message error" : "message";
}

async function request(path, options = {}) {
  const headers = Object.assign({ "Content-Type": "application/json" }, options.headers || {});
  const token = localStorage.getItem(tokenKey);
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(path, Object.assign({}, options, { headers }));
  let body = null;
  const text = await res.text();
  if (text) {
    try { body = JSON.parse(text); } catch { body = text; }
  }
  if (!res.ok) {
    const err = body && body.error ? body.error : `HTTP ${res.status}`;
    throw new Error(err);
  }
  return body;
}

async function signup() {
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;
  await request("/signup", { method: "POST", body: JSON.stringify({ email, password }) });
  setMessage("User created. Logging in...");
  await login();
}

async function login() {
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;
  const data = await request("/login", { method: "POST", body: JSON.stringify({ email, password }) });
  localStorage.setItem(tokenKey, data.token);
  window.location.href = "/todo";
}

function todoId(item) {
  return item.id || item.ID || item._id;
}

async function loadTodos() {
  const list = document.getElementById("todoList");
  if (!list) return;
  const items = await request("/todos");
  list.innerHTML = "";
  if (!items || items.length === 0) {
    const empty = document.createElement("li");
    empty.className = "empty";
    empty.textContent = "No todos yet.";
    list.appendChild(empty);
    return;
  }
  for (const item of items) {
    const li = document.createElement("li");
    li.className = item.done ? "done" : "";

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = !!item.done;
    checkbox.addEventListener("change", async () => {
      await request(`/todos/${todoId(item)}`, { method: "PATCH", body: JSON.stringify({ done: checkbox.checked }) });
      await loadTodos();
    });

    const span = document.createElement("span");
    span.textContent = item.title;

    const del = document.createElement("button");
    del.type = "button";
    del.className = "danger small";
    del.textContent = "Delete";
    del.addEventListener("click", async () => {
      await request(`/todos/${todoId(item)}`, { method: "DELETE" });
      await loadTodos();
    });

    li.appendChild(checkbox);
    li.appendChild(span);
    li.appendChild(del);
    list.appendChild(li);
  }
}

async function addTodo(event) {
  event.preventDefault();
  const input = document.getElementById("todoTitle");
  const title = input.value.trim();
  if (!title) return;
  await request("/todos", { method: "POST", body: JSON.stringify({ title }) });
  input.value = "";
  await loadTodos();
}

window.addEventListener("DOMContentLoaded", async () => {
  const signupBtn = document.getElementById("signupBtn");
  const loginBtn = document.getElementById("loginBtn");
  const todoForm = document.getElementById("todoForm");
  const logoutBtn = document.getElementById("logoutBtn");

  if (signupBtn) signupBtn.addEventListener("click", () => signup().catch(e => setMessage(e.message, true)));
  if (loginBtn) loginBtn.addEventListener("click", () => login().catch(e => setMessage(e.message, true)));
  if (todoForm) todoForm.addEventListener("submit", e => addTodo(e).catch(err => setMessage(err.message, true)));
  if (logoutBtn) logoutBtn.addEventListener("click", () => { localStorage.removeItem(tokenKey); window.location.href = "/"; });

  if (window.location.pathname === "/todo") {
    if (!localStorage.getItem(tokenKey)) {
      window.location.href = "/";
      return;
    }
    await loadTodos().catch(e => setMessage(e.message, true));
  }
});
