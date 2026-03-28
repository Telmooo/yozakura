// Yozakura - TS example
// These files are all gibberish, do not attempt to run them

//  Primitive Types & Variables 
const message: string = "Hello, TypeScript!";
let count: number = 42;
let bigNum: bigint = 9007199254740991n;
const active: boolean = true;
const nothing: null = null;
const missing: undefined = undefined;
const unique: symbol = Symbol("id");

//  Enums 
enum Direction {
  Up = "UP",
  Down = "DOWN",
  Left = "LEFT",
  Right = "RIGHT",
}

const enum Status {
  Pending,
  Active,
  Inactive,
  Banned,
}

//  Interfaces 
interface Entity {
  readonly id: string;
  createdAt: Date;
  updatedAt?: Date;
}

interface Serializable {
  toJSON(): Record<string, unknown>;
  toString(): string;
}

interface Repository<T extends Entity> {
  findById(id: string): Promise<T | null>;
  findAll(filter?: Partial<T>): Promise<T[]>;
  save(entity: T): Promise<T>;
  delete(id: string): Promise<void>;
}

//  Type Aliases 
type ID = string | number;
type Nullable<T> = T | null;
type Optional<T> = T | undefined;
type DeepReadonly<T> = { readonly [K in keyof T]: DeepReadonly<T[K]> };
type Awaited<T> = T extends Promise<infer U> ? U : T;

//  Union & Intersection Types 
type StringOrNumber = string | number;
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };

type WithTimestamps<T> = T & {
  createdAt: Date;
  updatedAt: Date;
};

//  Mapped & Conditional Types 
type Mutable<T> = { -readonly [K in keyof T]: T[K] };
type RequiredKeys<T> = { [K in keyof T]-?: undefined extends T[K] ? never : K }[keyof T];
type OptionalKeys<T> = { [K in keyof T]: undefined extends T[K] ? K : never }[keyof T];

type IsString<T> = T extends string ? true : false;
type Flatten<T> = T extends Array<infer U> ? U : T;

//  Template Literal Types 
type EventName = `on${Capitalize<string>}`;
type CSSProperty = `--${string}`;
type Route = `/api/${string}`;

//  Generics 
function identity<T>(value: T): T {
  return value;
}

function first<T extends readonly unknown[]>(arr: T): T[0] {
  return arr[0];
}

function merge<A, B>(a: A, b: B): A & B {
  return { ...a, ...b } as A & B;
}

class Stack<T> {
  private items: T[] = [];

  push(item: T): this {
    this.items.push(item);
    return this;
  }

  pop(): T | undefined {
    return this.items.pop();
  }

  peek(): T | undefined {
    return this.items[this.items.length - 1];
  }

  get size(): number {
    return this.items.length;
  }

  [Symbol.iterator](): Iterator<T> {
    let index = this.items.length - 1;
    const items = this.items;
    return {
      next(): IteratorResult<T> {
        return index >= 0
          ? { value: items[index--], done: false }
          : { value: undefined as never, done: true };
      },
    };
  }
}

//  Decorators 
function log(target: unknown, key: string, descriptor: PropertyDescriptor) {
  const original = descriptor.value;
  descriptor.value = function (...args: unknown[]) {
    console.log(`Calling ${key} with`, args);
    const result = original.apply(this, args);
    console.log(`${key} returned`, result);
    return result;
  };
  return descriptor;
}

function singleton<T extends { new (...args: unknown[]): object }>(constructor: T) {
  let instance: InstanceType<T>;
  return class extends constructor {
    constructor(...args: unknown[]) {
      super(...args);
      if (instance) return instance;
      instance = this as InstanceType<T>;
    }
  };
}

//  Abstract Classes 
abstract class Shape {
  abstract readonly type: string;
  abstract area(): number;
  abstract perimeter(): number;

  describe(): string {
    return `${this.type}: area=${this.area().toFixed(2)}, perimeter=${this.perimeter().toFixed(2)}`;
  }
}

class Circle extends Shape {
  readonly type = "Circle";
  constructor(public readonly radius: number) {
    super();
  }
  area() { return Math.PI * this.radius ** 2; }
  perimeter() { return 2 * Math.PI * this.radius; }
}

class Rectangle extends Shape {
  readonly type = "Rectangle";
  constructor(
    public readonly width: number,
    public readonly height: number
  ) {
    super();
  }
  area() { return this.width * this.height; }
  perimeter() { return 2 * (this.width + this.height); }
}

//  Utility Types 
interface User {
  id: string;
  name: string;
  email: string;
  role: "admin" | "user" | "guest";
  age?: number;
}

type UserPreview = Pick<User, "id" | "name">;
type UserUpdate = Partial<Omit<User, "id">>;
type ReadonlyUser = Readonly<User>;
type UserRecord = Record<string, User>;
type NonNullableUser = NonNullable<User | null | undefined>;
type UserKeys = keyof User;
type ReturnTypeExample = ReturnType<typeof identity>;
type ParametersExample = Parameters<typeof merge>;

//  Namespaces 
namespace Validation {
  export interface Validator<T> {
    validate(value: unknown): value is T;
    message: string;
  }

  export class StringValidator implements Validator<string> {
    message = "Must be a string";
    validate(value: unknown): value is string {
      return typeof value === "string";
    }
  }

  export function createValidator<T>(
    predicate: (v: unknown) => v is T,
    message: string
  ): Validator<T> {
    return { validate: predicate, message };
  }
}

//  Type Guards & Assertions 
function isString(value: unknown): value is string {
  return typeof value === "string";
}

function assertNonNull<T>(value: T, message: string): asserts value is NonNullable<T> {
  if (value == null) throw new Error(message);
}

function exhaustive(value: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(value)}`);
}

//  Async Patterns 
async function retry<T>(
  fn: () => Promise<T>,
  options: { retries: number; delay: number } = { retries: 3, delay: 1000 }
): Promise<T> {
  let lastError: unknown;
  for (let i = 0; i <= options.retries; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (i < options.retries) {
        await new Promise((r) => setTimeout(r, options.delay * 2 ** i));
      }
    }
  }
  throw lastError;
}

type AsyncResult<T> = Promise<Result<T>>;

async function safeRun<T>(fn: () => Promise<T>): AsyncResult<T> {
  try {
    return { ok: true, value: await fn() };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error : new Error(String(error)) };
  }
}
