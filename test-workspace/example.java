// Yozakura - Java example
// These files are all gibberish, do not attempt to run them

//  Package & Imports
package com.example.yozakura;

import java.util.*;
import java.util.concurrent.*;
import java.util.function.*;
import java.util.stream.*;
import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.lang.annotation.*;

//  Annotations
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
@interface Audited {
    String value() default "default";
    boolean log() default true;
}

@FunctionalInterface
interface Transformer<T, R> {
    R transform(T input);

    default <V> Transformer<T, V> andThen(Transformer<R, V> after) {
        return input -> after.transform(this.transform(input));
    }
}

//  Enums
enum Status {
    PENDING("Pending", 0),
    ACTIVE("Active", 1),
    INACTIVE("Inactive", 2),
    BANNED("Banned", -1);

    private final String label;
    private final int code;

    Status(String label, int code) {
        this.label = label;
        this.code = code;
    }

    public String getLabel() { return label; }
    public int getCode() { return code; }

    public boolean isAccessible() {
        return this == PENDING || this == ACTIVE;
    }

    public static Optional<Status> fromCode(int code) {
        return Arrays.stream(values())
            .filter(s -> s.code == code)
            .findFirst();
    }
}

//  Records
record Point(double x, double y) {
    // Compact constructor with validation
    Point {
        if (Double.isNaN(x) || Double.isNaN(y)) {
            throw new IllegalArgumentException("Coordinates must be valid numbers");
        }
    }

    double distance(Point other) {
        double dx = this.x - other.x;
        double dy = this.y - other.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    Point translate(double dx, double dy) {
        return new Point(x + dx, y + dy);
    }

    static Point origin() { return new Point(0, 0); }
}

record UserDTO(String id, String name, String email) {}

//  Sealed Classes
sealed interface Shape permits Circle, Rectangle, Triangle {
    double area();
    double perimeter();

    default String describe() {
        return switch (this) {
            case Circle c    -> "Circle with radius " + c.radius();
            case Rectangle r -> "Rectangle " + r.width() + "x" + r.height();
            case Triangle t  -> "Triangle with base " + t.base();
        };
    }
}

record Circle(Point center, double radius) implements Shape {
    public double area()      { return Math.PI * radius * radius; }
    public double perimeter() { return 2 * Math.PI * radius; }
}

record Rectangle(Point topLeft, double width, double height) implements Shape {
    public double area()      { return width * height; }
    public double perimeter() { return 2 * (width + height); }
}

record Triangle(double base, double height, double hypotenuse) implements Shape {
    public double area()      { return 0.5 * base * height; }
    public double perimeter() { return base + height + hypotenuse; }
}

//  Generic Classes
class Result<T> {
    private final T value;
    private final Exception error;

    private Result(T value, Exception error) {
        this.value = value;
        this.error = error;
    }

    public static <T> Result<T> ok(T value) {
        return new Result<>(value, null);
    }

    public static <T> Result<T> failure(Exception error) {
        return new Result<>(null, error);
    }

    public boolean isOk()      { return error == null; }
    public T getValue()        { return value; }
    public Exception getError() { return error; }

    public <U> Result<U> map(Function<T, U> mapper) {
        if (isOk()) {
            try {
                return Result.ok(mapper.apply(value));
            } catch (Exception e) {
                return Result.failure(e);
            }
        }
        return Result.failure(error);
    }

    public T orElse(T defaultValue) {
        return isOk() ? value : defaultValue;
    }

    @Override
    public String toString() {
        return isOk() ? "Ok(" + value + ")" : "Err(" + error.getMessage() + ")";
    }
}

//  Abstract Classes
abstract class AbstractRepository<T, ID> {
    protected final Map<ID, T> store = new HashMap<>();

    public abstract T findById(ID id);
    public abstract T save(T entity);

    public List<T> findAll() {
        return new ArrayList<>(store.values());
    }

    public void delete(ID id) {
        store.remove(id);
    }

    public long count() {
        return store.size();
    }
}

//  Interfaces with Default Methods
interface Auditable {
    Instant getCreatedAt();
    Instant getUpdatedAt();
    String getCreatedBy();

    default boolean isRecent(Duration threshold) {
        return getCreatedAt().isAfter(Instant.now().minus(threshold));
    }
}

interface Cacheable<K> {
    K getCacheKey();
    Duration getTtl();

    default boolean isExpired(Instant cachedAt) {
        return Instant.now().isAfter(cachedAt.plus(getTtl()));
    }
}

//  Main Class
@Audited("main")
public class Main {

    //  Lambda & Streams
    static void demonstrateStreams() {
        List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

        // Intermediate & terminal operations
        int sumOfSquares = numbers.stream()
            .filter(n -> n % 2 == 0)
            .map(n -> n * n)
            .reduce(0, Integer::sum);

        List<String> strings = numbers.stream()
            .map(Object::toString)
            .collect(Collectors.toList());

        Map<Boolean, List<Integer>> partitioned = numbers.stream()
            .collect(Collectors.partitioningBy(n -> n % 2 == 0));

        Map<Integer, List<Integer>> grouped = numbers.stream()
            .collect(Collectors.groupingBy(n -> n % 3));

        OptionalInt max = numbers.stream().mapToInt(i -> i).max();
        double avg = numbers.stream().mapToInt(i -> i).average().orElse(0);

        // FlatMap
        List<List<Integer>> nested = List.of(List.of(1, 2), List.of(3, 4), List.of(5, 6));
        List<Integer> flat = nested.stream()
            .flatMap(Collection::stream)
            .collect(Collectors.toList());

        // String joining
        String joined = numbers.stream()
            .map(Object::toString)
            .collect(Collectors.joining(", ", "[", "]"));
    }

    //  Switch Expressions
    static String classify(Object obj) {
        return switch (obj) {
            case Integer i when i < 0 -> "negative int: " + i;
            case Integer i            -> "positive int: " + i;
            case String s when s.isEmpty() -> "empty string";
            case String s             -> "string: " + s;
            case null                 -> "null";
            default                   -> "other: " + obj.getClass().getSimpleName();
        };
    }

    //  Var & instanceof Pattern
    static void demonstrateModernFeatures() {
        var list = new ArrayList<String>();
        var map = new HashMap<String, Integer>();

        Object value = "Hello, World!";
        if (value instanceof String s && s.length() > 5) {
            System.out.println("Long string: " + s.toUpperCase());
        }
    }

    //  Concurrency
    static void demonstrateConcurrency() throws Exception {
        var executor = Executors.newVirtualThreadPerTaskExecutor();
        var futures = new ArrayList<CompletableFuture<String>>();

        for (int i = 0; i < 10; i++) {
            final int id = i;
            futures.add(CompletableFuture.supplyAsync(
                () -> "Result " + id,
                executor
            ));
        }

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
            .thenRun(() -> futures.forEach(f -> {
                try { System.out.println(f.get()); }
                catch (Exception e) { e.printStackTrace(); }
            }))
            .get();

        executor.shutdown();
    }

    public static void main(String[] args) {
        // Shapes
        Shape circle = new Circle(new Point(0, 0), 5.0);
        Shape rect = new Rectangle(new Point(0, 4), 3.0, 4.0);

        List.of(circle, rect).forEach(s -> System.out.printf(
            "%s: area=%.2f, perimeter=%.2f%n", s.describe(), s.area(), s.perimeter()
        ));

        // Records
        var p1 = new Point(0, 0);
        var p2 = new Point(3, 4);
        System.out.printf("Distance: %.2f%n", p1.distance(p2));

        // Result
        Result<Integer> r = Result.ok(42).map(n -> n * 2);
        System.out.println(r);

        // Status enum
        Status.fromCode(1).ifPresent(s -> System.out.println(s.getLabel()));

        demonstrateStreams();
    }
}
