// Yozakura - TSX example
// These files are all gibberish, do not attempt to run them
import React, {
  createContext,
  forwardRef,
  lazy,
  memo,
  Suspense,
  useCallback,
  useContext,
  useEffect,
  useId,
  useImperativeHandle,
  useMemo,
  useReducer,
  useRef,
  useState,
  type ComponentPropsWithoutRef,
  type ElementRef,
  type FC,
  type ReactNode,
  type Ref,
} from "react";

//  Types
type Theme = "light" | "dark" | "system";
type Size  = "xs" | "sm" | "md" | "lg" | "xl";

interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: "admin" | "user" | "guest";
}

interface Post {
  id: string;
  title: string;
  body: string;
  author: User;
  tags: string[];
  publishedAt: Date | null;
  likeCount: number;
}

//  Context
interface ThemeContextValue {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  resolvedTheme: "light" | "dark";
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider");
  return ctx;
}

function ThemeProvider({ children, defaultTheme = "system" }: {
  children: ReactNode;
  defaultTheme?: Theme;
}) {
  const [theme, setTheme] = useState<Theme>(defaultTheme);

  const resolvedTheme = useMemo<"light" | "dark">(() => {
    if (theme !== "system") return theme;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }, [theme]);

  useEffect(() => {
    document.documentElement.dataset.theme = resolvedTheme;
  }, [resolvedTheme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme, resolvedTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

//  useReducer
type CartItem = { id: string; name: string; price: number; qty: number };

type CartAction =
  | { type: "ADD";    item: Omit<CartItem, "qty"> }
  | { type: "REMOVE"; id: string }
  | { type: "UPDATE"; id: string; qty: number }
  | { type: "CLEAR" };

function cartReducer(state: CartItem[], action: CartAction): CartItem[] {
  switch (action.type) {
    case "ADD": {
      const existing = state.find((i) => i.id === action.item.id);
      if (existing) {
        return state.map((i) => i.id === action.item.id ? { ...i, qty: i.qty + 1 } : i);
      }
      return [...state, { ...action.item, qty: 1 }];
    }
    case "REMOVE":
      return state.filter((i) => i.id !== action.id);
    case "UPDATE":
      return action.qty <= 0
        ? state.filter((i) => i.id !== action.id)
        : state.map((i) => i.id === action.id ? { ...i, qty: action.qty } : i);
    case "CLEAR":
      return [];
  }
}

function useCart() {
  const [items, dispatch] = useReducer(cartReducer, []);

  const total = useMemo(
    () => items.reduce((sum, i) => sum + i.price * i.qty, 0),
    [items]
  );

  return { items, total, dispatch };
}

//  Custom Hooks
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debounced;
}

function useFetch<T>(url: string) {
  const [data, setData]     = useState<T | null>(null);
  const [error, setError]   = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);
  const abortRef = useRef<AbortController>(null);

  useEffect(() => {
    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;
    setLoading(true);
    setError(null);

    fetch(url, { signal: controller.signal })
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json() as Promise<T>;
      })
      .then(setData)
      .catch((err) => {
        if (err.name !== "AbortError") setError(err);
      })
      .finally(() => setLoading(false));

    return () => controller.abort();
  }, [url]);

  return { data, error, loading };
}

function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? (JSON.parse(item) as T) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = useCallback(
    (value: T | ((prev: T) => T)) => {
      setStoredValue((prev) => {
        const next = typeof value === "function" ? (value as (p: T) => T)(prev) : value;
        window.localStorage.setItem(key, JSON.stringify(next));
        return next;
      });
    },
    [key]
  );

  return [storedValue, setValue] as const;
}

//  forwardRef Component
interface InputProps extends ComponentPropsWithoutRef<"input"> {
  label: string;
  error?: string;
  hint?: string;
}

interface InputHandle {
  focus(): void;
  clear(): void;
}

const Input = forwardRef<InputHandle, InputProps>(function Input(
  { label, error, hint, className, id: propId, ...rest },
  ref
) {
  const generatedId = useId();
  const id          = propId ?? generatedId;
  const inputRef    = useRef<HTMLInputElement>(null);

  useImperativeHandle(ref, () => ({
    focus: () => inputRef.current?.focus(),
    clear: () => {
      if (inputRef.current) inputRef.current.value = "";
    },
  }));

  return (
    <div className={`field ${className ?? ""}`}>
      <label htmlFor={id} className="field__label">
        {label}
      </label>
      <input
        ref={inputRef}
        id={id}
        aria-describedby={hint ? `${id}-hint` : undefined}
        aria-invalid={error ? "true" : undefined}
        className={`field__input ${error ? "field__input--error" : ""}`}
        {...rest}
      />
      {hint && (
        <p id={`${id}-hint`} className="field__hint">
          {hint}
        </p>
      )}
      {error && (
        <p role="alert" className="field__error">
          {error}
        </p>
      )}
    </div>
  );
});

//  Compound Component
interface ButtonProps extends ComponentPropsWithoutRef<"button"> {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  size?: Size;
  loading?: boolean;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
}

const Button: FC<ButtonProps> = memo(function Button({
  variant = "primary",
  size = "md",
  loading = false,
  leftIcon,
  rightIcon,
  children,
  disabled,
  className,
  ...rest
}) {
  return (
    <button
      disabled={disabled || loading}
      aria-busy={loading}
      className={[
        "btn",
        `btn--${variant}`,
        `btn--${size}`,
        loading && "btn--loading",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      {...rest}
    >
      {loading ? (
        <span className="btn__spinner" aria-hidden="true" />
      ) : (
        leftIcon && <span className="btn__icon btn__icon--left">{leftIcon}</span>
      )}
      <span className="btn__label">{children}</span>
      {!loading && rightIcon && (
        <span className="btn__icon btn__icon--right">{rightIcon}</span>
      )}
    </button>
  );
});

//  Card Component
function PostCard({ post, onLike }: { post: Post; onLike: (id: string) => void }) {
  const { resolvedTheme } = useTheme();
  const [liked, setLiked] = useState(false);

  const handleLike = useCallback(() => {
    setLiked((prev) => !prev);
    onLike(post.id);
  }, [post.id, onLike]);

  const formattedDate = useMemo(
    () =>
      post.publishedAt
        ? new Intl.DateTimeFormat("en-GB", {
            dateStyle: "medium",
          }).format(post.publishedAt)
        : "Draft",
    [post.publishedAt]
  );

  return (
    <article
      className={`post-card post-card--${resolvedTheme}`}
      aria-labelledby={`post-${post.id}-title`}
    >
      <header className="post-card__header">
        <h2 id={`post-${post.id}-title`} className="post-card__title">
          {post.title}
        </h2>
        <div className="post-card__meta">
          <img
            src={post.author.avatar ?? "/default-avatar.png"}
            alt=""
            aria-hidden="true"
            className="post-card__avatar"
            width={32}
            height={32}
          />
          <span className="post-card__author">{post.author.name}</span>
          <time dateTime={post.publishedAt?.toISOString()}>{formattedDate}</time>
        </div>
      </header>

      <p className="post-card__body">{post.body}</p>

      {post.tags.length > 0 && (
        <ul className="post-card__tags" aria-label="Tags">
          {post.tags.map((tag) => (
            <li key={tag} className="tag">
              #{tag}
            </li>
          ))}
        </ul>
      )}

      <footer className="post-card__footer">
        <Button
          variant={liked ? "primary" : "ghost"}
          size="sm"
          onClick={handleLike}
          aria-pressed={liked}
          aria-label={`${liked ? "Unlike" : "Like"} post: ${post.title}`}
        >
          ♥ {post.likeCount + (liked ? 1 : 0)}
        </Button>
      </footer>
    </article>
  );
}

//  Lazy & Suspense
const HeavyChart = lazy(() => import("./HeavyChart"));

function Dashboard() {
  const { data: posts, loading, error } = useFetch<Post[]>("/api/posts");
  const [query, setQuery] = useState("");
  const debouncedQuery    = useDebounce(query, 300);
  const inputRef          = useRef<ElementRef<typeof Input>>(null);

  const filteredPosts = useMemo(
    () =>
      (posts ?? []).filter(
        (p) =>
          p.title.toLowerCase().includes(debouncedQuery.toLowerCase()) ||
          p.body.toLowerCase().includes(debouncedQuery.toLowerCase())
      ),
    [posts, debouncedQuery]
  );

  const handleLike = useCallback((id: string) => {
    console.log("Liked post:", id);
  }, []);

  if (loading) return <p aria-live="polite">Loading…</p>;
  if (error)   return <p role="alert">Error: {error.message}</p>;

  return (
    <main>
      <header>
        <h1>Dashboard</h1>
        <Input
          ref={inputRef}
          label="Search posts"
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search…"
          hint="Filter by title or content"
        />
      </header>

      <Suspense fallback={<div className="skeleton" style={{ height: 200 }} />}>
        <HeavyChart data={filteredPosts} />
      </Suspense>

      <section aria-label="Post list">
        {filteredPosts.length === 0 ? (
          <p>No posts found{debouncedQuery ? ` for "${debouncedQuery}"` : ""}.</p>
        ) : (
          <ul className="post-grid" role="list">
            {filteredPosts.map((post) => (
              <li key={post.id}>
                <PostCard post={post} onLike={handleLike} />
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}

//  App Root
export default function App() {
  return (
    <ThemeProvider defaultTheme="dark">
      <Dashboard />
    </ThemeProvider>
  );
}
