// Yozakura - Rust example
// These files are all gibberish, do not attempt to run them

//  Modules & Imports 
use std::collections::{HashMap, HashSet};
use std::fmt;
use std::sync::{Arc, Mutex};

//  Constants 
const MAX_RETRIES: u32 = 3;
const PI: f64 = std::f64::consts::PI;
static APP_NAME: &str = "yozakura";

//  Type Aliases 
type Result<T, E = AppError> = std::result::Result<T, E>;
type BoxedFuture<T> = std::pin::Pin<Box<dyn std::future::Future<Output = T> + Send>>;

//  Enums 
#[derive(Debug, Clone, PartialEq)]
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle { base: f64, height: f64 },
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle { base, height } => 0.5 * base * height,
        }
    }

    fn perimeter(&self) -> f64 {
        match self {
            Shape::Circle { radius } => 2.0 * PI * radius,
            Shape::Rectangle { width, height } => 2.0 * (width + height),
            Shape::Triangle { base, height } => {
                let hypotenuse = (base * base + height * height).sqrt();
                base + height + hypotenuse
            }
        }
    }
}

impl fmt::Display for Shape {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?} (area={:.2})", self, self.area())
    }
}

//  Error Handling 
#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Validation error on field '{field}': {message}")]
    Validation { field: String, message: String },

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Parse error: {0}")]
    Parse(String),
}

//  Structs 
#[derive(Debug, Clone)]
struct Point {
    x: f64,
    y: f64,
}

impl Point {
    fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }

    fn distance(&self, other: &Self) -> f64 {
        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()
    }

    fn origin() -> Self {
        Self { x: 0.0, y: 0.0 }
    }
}

impl std::ops::Add for Point {
    type Output = Self;

    fn add(self, rhs: Self) -> Self::Output {
        Self::new(self.x + rhs.x, self.y + rhs.y)
    }
}

impl Default for Point {
    fn default() -> Self {
        Self::origin()
    }
}

//  Traits 
trait Area {
    fn area(&self) -> f64;
}

trait Perimeter {
    fn perimeter(&self) -> f64;
}

trait Geometry: Area + Perimeter + fmt::Debug {
    fn describe(&self) -> String {
        format!("{:?}: area={:.2}, perimeter={:.2}", self, self.area(), self.perimeter())
    }
}

//  Generics & Lifetimes 
struct Cache<'a, K, V> {
    store: HashMap<K, V>,
    name: &'a str,
}

impl<'a, K, V> Cache<'a, K, V>
where
    K: std::hash::Hash + Eq + Clone,
    V: Clone,
{
    fn new(name: &'a str) -> Self {
        Self {
            store: HashMap::new(),
            name,
        }
    }

    fn get(&self, key: &K) -> Option<&V> {
        self.store.get(key)
    }

    fn insert(&mut self, key: K, value: V) -> Option<V> {
        self.store.insert(key, value)
    }

    fn get_or_insert_with<F>(&mut self, key: K, f: F) -> &V
    where
        F: FnOnce() -> V,
    {
        self.store.entry(key).or_insert_with(f)
    }
}

//  Closures & Iterators 
fn demonstrate_iterators() {
    let numbers = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    let sum: i32 = numbers.iter().sum();
    let evens: Vec<_> = numbers.iter().filter(|&&x| x % 2 == 0).collect();
    let doubled: Vec<_> = numbers.iter().map(|&x| x * 2).collect();
    let sum_of_even_squares: i32 = numbers
        .iter()
        .filter(|&&x| x % 2 == 0)
        .map(|&x| x * x)
        .sum();

    let words = vec!["hello", "world", "rust"];
    let sentence = words.join(", ");
    let upper: Vec<_> = words.iter().map(|s| s.to_uppercase()).collect();

    // Chain & zip
    let a = vec![1, 2, 3];
    let b = vec![4, 5, 6];
    let combined: Vec<_> = a.iter().chain(b.iter()).collect();
    let pairs: Vec<_> = a.iter().zip(b.iter()).collect();

    // Flatten
    let nested = vec![vec![1, 2], vec![3, 4], vec![5, 6]];
    let flat: Vec<_> = nested.into_iter().flatten().collect();

    // Fold
    let product = numbers.iter().fold(1, |acc, &x| acc * x);

    // Scan (running sum)
    let running_sum: Vec<_> = numbers
        .iter()
        .scan(0, |state, &x| {
            *state += x;
            Some(*state)
        })
        .collect();
}

//  Pattern Matching 
fn classify_number(n: i64) -> &'static str {
    match n {
        i64::MIN..=-1 => "negative",
        0 => "zero",
        1..=9 => "single digit",
        10..=99 => "double digit",
        100..=999 => "triple digit",
        _ => "large",
    }
}

fn process_option<T: fmt::Debug>(opt: Option<T>) -> String {
    match opt {
        Some(ref value) if format!("{:?}", value).len() > 10 => format!("Large: {:?}", value),
        Some(value) => format!("Small: {:?}", value),
        None => "Nothing".to_string(),
    }
}

//  Smart Pointers 
fn demonstrate_smart_pointers() {
    // Box - heap allocation
    let boxed: Box<i32> = Box::new(42);
    let boxed_slice: Box<[i32]> = vec![1, 2, 3].into_boxed_slice();

    // Rc - reference counting
    let shared = std::rc::Rc::new(vec![1, 2, 3]);
    let clone1 = std::rc::Rc::clone(&shared);
    let clone2 = std::rc::Rc::clone(&shared);

    // Arc + Mutex - thread-safe shared state
    let counter = Arc::new(Mutex::new(0));
    let counter_clone = Arc::clone(&counter);

    std::thread::spawn(move || {
        let mut num = counter_clone.lock().unwrap();
        *num += 1;
    });
}

//  Macros 
macro_rules! hashmap {
    ($($key:expr => $value:expr),* $(,)?) => {{
        let mut map = HashMap::new();
        $(map.insert($key, $value);)*
        map
    }};
}

macro_rules! assert_approx_eq {
    ($left:expr, $right:expr, $epsilon:expr) => {
        assert!(
            ($left - $right).abs() < $epsilon,
            "assertion failed: |{} - {}| = {} >= {}",
            $left, $right, ($left - $right).abs(), $epsilon
        );
    };
}

//  Async 
async fn fetch_data(url: &str) -> Result<String> {
    // Simulate async work
    tokio::time::sleep(std::time::Duration::from_millis(10)).await;
    Ok(format!("data from {url}"))
}

async fn parallel_fetch(urls: &[&str]) -> Vec<Result<String>> {
    let futures: Vec<_> = urls.iter().map(|url| fetch_data(url)).collect();
    futures::future::join_all(futures).await
}

//  Main 
fn main() {
    let circle = Shape::Circle { radius: 5.0 };
    let rect = Shape::Rectangle { width: 4.0, height: 6.0 };

    println!("{}", circle);
    println!("{}", rect);

    let p1 = Point::new(0.0, 0.0);
    let p2 = Point::new(3.0, 4.0);
    println!("Distance: {:.2}", p1.distance(&p2));

    let mut cache: Cache<&str, i32> = Cache::new("test");
    cache.insert("key", 42);

    let map = hashmap! {
        "one" => 1,
        "two" => 2,
        "three" => 3,
    };

    demonstrate_iterators();
}
