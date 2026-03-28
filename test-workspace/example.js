// Yozakura - JS example
// These files are all gibberish, do not attempt to run them

//  Imports & Exports
import fs from "node:fs/promises";
import { EventEmitter } from "node:events";
import path, { join, resolve } from "node:path";

export const VERSION = "1.0.0";
export default class Application {}

//  Constants & Primitives
const MAX_RETRIES = 3;
const PI = 3.14159265358979;
const isProduction = process.env.NODE_ENV === "production";
const nothing = null;
const missing = undefined;

//  Template Literals
const greeting = (name, age) => `Hello, ${name}! You are ${age} years old.`;
const multiLine = `
  First line
  Second line: ${1 + 2}
  Third line
`;

//  Regular Expressions
const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const urlPattern = new RegExp("https?://[\\w./]+", "gi");

//  Destructuring
const { name: firstName, age = 25, ...rest } = { name: "Alice", age: 30, city: "City" };
const [head, second, ...tail] = [1, 2, 3, 4, 5];

//  Classes
class Animal {
  #name; // private field
  static count = 0;

  constructor(name, sound) {
    this.#name = name;
    this.sound = sound;
    Animal.count++;
  }

  get name() {
    return this.#name;
  }

  speak() {
    return `${this.#name} says ${this.sound}!`;
  }

  toString() {
    return `Animal(${this.#name})`;
  }

  static reset() {
    Animal.count = 0;
  }
}

class Dog extends Animal {
  #tricks = [];

  constructor(name) {
    super(name, "woof");
  }

  learn(trick) {
    this.#tricks.push(trick);
    return this;
  }

  perform() {
    return this.#tricks.map((t) => `${this.name} performs: ${t}`);
  }
}

//  Async / Await
async function fetchUser(id) {
  try {
    const response = await fetch(`https://api.example.com/users/${id}`);
    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }
    const data = await response.json();
    return data;
  } catch (error) {
    if (error instanceof TypeError) {
      console.error("Network error:", error.message);
    } else {
      console.error("Unexpected error:", error);
    }
    throw error;
  } finally {
    console.log("fetchUser completed");
  }
}

//  Promises
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const withRetry = (fn, retries = MAX_RETRIES) =>
  fn().catch((err) =>
    retries > 0
      ? delay(1000).then(() => withRetry(fn, retries - 1))
      : Promise.reject(err)
  );

Promise.allSettled([fetchUser(1), fetchUser(2), fetchUser(3)]).then((results) => {
  results.forEach(({ status, value, reason }) => {
    if (status === "fulfilled") console.log(value);
    else console.warn("Failed:", reason);
  });
});

//  Generators
function* range(start, end, step = 1) {
  for (let i = start; i < end; i += step) {
    yield i;
  }
}

async function* asyncRange(start, end) {
  for (let i = start; i < end; i++) {
    await delay(10);
    yield i;
  }
}

//  Higher-Order Functions
const compose =
  (...fns) =>
  (x) =>
    fns.reduceRight((acc, fn) => fn(acc), x);

const pipe =
  (...fns) =>
  (x) =>
    fns.reduce((acc, fn) => fn(acc), x);

const memoize = (fn) => {
  const cache = new Map();
  return (...args) => {
    const key = JSON.stringify(args);
    if (cache.has(key)) return cache.get(key);
    const result = fn(...args);
    cache.set(key, result);
    return result;
  };
};

//  Optional Chaining & Nullish Coalescing
const user = {
  profile: {
    address: {
      city: "City",
    },
  },
};

const city = user?.profile?.address?.city ?? "Unknown";
const zip = user?.profile?.address?.zip ?? "N/A";
const adminEmail = user?.admin?.email ?? null;

//  Spread & Rest
const defaults = { timeout: 5000, retries: 3, verbose: false };
const options = { ...defaults, timeout: 10000, debug: true };

function sum(...numbers) {
  return numbers.reduce((a, b) => a + b, 0);
}

//  Symbols & WeakMap
const id = Symbol("id");
const secret = Symbol.for("app.secret");

const privateData = new WeakMap();
class SecureStore {
  constructor(data) {
    privateData.set(this, data);
  }
  get() {
    return privateData.get(this);
  }
}

//  Proxy & Reflect
const handler = {
  get(target, prop, receiver) {
    console.log(`Getting: ${String(prop)}`);
    return Reflect.get(target, prop, receiver);
  },
  set(target, prop, value) {
    if (typeof value !== "number") throw new TypeError("Only numbers allowed");
    return Reflect.set(target, prop, value);
  },
};

const numbers = new Proxy({}, handler);

//  Error Types
class AppError extends Error {
  constructor(message, code, cause) {
    super(message, { cause });
    this.name = "AppError";
    this.code = code;
  }
}

class ValidationError extends AppError {
  constructor(field, message) {
    super(message, "VALIDATION_ERROR");
    this.name = "ValidationError";
    this.field = field;
  }
}

//  Array Methods
const data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
const evens = data.filter((n) => n % 2 === 0);
const doubled = data.map((n) => n * 2);
const total = data.reduce((acc, n) => acc + n, 0);
const found = data.find((n) => n > 5);
const allPositive = data.every((n) => n > 0);
const hasNeg = data.some((n) => n < 0);
const flat = [[1, 2], [3, [4, 5]]].flat(Infinity);

//  WeakRef & FinalizationRegistry
const registry = new FinalizationRegistry((value) => {
  console.log(`${value} was garbage collected`);
});

let obj = { name: "temp" };
const ref = new WeakRef(obj);
registry.register(obj, "temp-object");
