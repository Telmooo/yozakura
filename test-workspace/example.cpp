/*
 * Yozakura - C++ example
 * These files are all gibberish, do not attempt to run them
 */
#pragma once
#ifndef EXAMPLE_HPP
#define EXAMPLE_HPP

#include <algorithm>
#include <array>
#include <cassert>
#include <concepts>
#include <coroutine>
#include <expected>
#include <format>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <numeric>
#include <optional>
#include <ranges>
#include <span>
#include <stdexcept>
#include <string>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <variant>
#include <vector>

#define NODISCARD [[nodiscard]]
#define LIKELY(x) __builtin_expect(!!(x), 1)
#define UNLIKELY(x) __builtin_expect(!!(x), 0)

// Namespaces
namespace yozakura {
namespace detail {

template <typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

template <typename T>
concept Printable = requires(T t, std::ostream& os) { os << t; };

} // namespace detail

//  Constants 
inline constexpr double PI = 3.14159265358979323846;
inline constexpr std::string_view APP_NAME = "yozakura";
inline constexpr int MAX_RETRIES = 3;

//  Type Aliases 
using ID = std::uint64_t;
using StringMap = std::unordered_map<std::string, std::string>;
template <typename T>
using Optional = std::optional<T>;
template <typename T, typename E = std::string>
using Result = std::expected<T, E>;

//  Enums 
enum class Status : std::uint8_t {
    Pending = 0,
    Active  = 1,
    Inactive = 2,
    Banned  = 255,
};

enum class Direction {
    North, South, East, West
};

std::string_view to_string(Status s) {
    switch (s) {
        case Status::Pending:  return "Pending";
        case Status::Active:   return "Active";
        case Status::Inactive: return "Inactive";
        case Status::Banned:   return "Banned";
    }
    std::unreachable();
}

//  Structs & Classes 
struct Point {
    double x{}, y{};

    constexpr Point() = default;
    constexpr Point(double x, double y) noexcept : x{x}, y{y} {}

    constexpr Point operator+(const Point& rhs) const noexcept {
        return {x + rhs.x, y + rhs.y};
    }

    constexpr Point operator-(const Point& rhs) const noexcept {
        return {x - rhs.x, y - rhs.y};
    }

    constexpr Point operator*(double scalar) const noexcept {
        return {x * scalar, y * scalar};
    }

    constexpr bool operator==(const Point&) const noexcept = default;

    double distance(const Point& other) const noexcept {
        auto dx = x - other.x;
        auto dy = y - other.y;
        return std::sqrt(dx * dx + dy * dy);
    }

    friend std::ostream& operator<<(std::ostream& os, const Point& p) {
        return os << std::format("({:.2f}, {:.2f})", p.x, p.y);
    }
};

//  Templates 
template <detail::Numeric T>
class Stack {
public:
    using value_type = T;
    using size_type  = std::size_t;

    void push(T value) { data_.push_back(std::move(value)); }

    Optional<T> pop() {
        if (data_.empty()) return std::nullopt;
        T val = std::move(data_.back());
        data_.pop_back();
        return val;
    }

    NODISCARD Optional<T> peek() const {
        if (data_.empty()) return std::nullopt;
        return data_.back();
    }

    NODISCARD bool empty() const noexcept { return data_.empty(); }
    NODISCARD size_type size() const noexcept { return data_.size(); }

    // Iterator support
    auto begin() { return data_.begin(); }
    auto end()   { return data_.end(); }
    auto begin() const { return data_.cbegin(); }
    auto end()   const { return data_.cend(); }

private:
    std::vector<T> data_;
};

// Template specialization
template <>
class Stack<bool> {
public:
    void push(bool value) { bits_.push_back(value); }
    Optional<bool> pop() {
        if (bits_.empty()) return std::nullopt;
        bool val = bits_.back();
        bits_.pop_back();
        return val;
    }
private:
    std::vector<bool> bits_;
};

//  Variadic Templates 
template <typename... Args>
void print(Args&&... args) {
    ((std::cout << std::forward<Args>(args) << ' '), ...);
    std::cout << '\n';
}

template <detail::Numeric T, detail::Numeric... Ts>
constexpr T sum(T first, Ts... rest) {
    return (first + ... + rest);
}

//  Concepts 
template <typename Container>
concept Iterable = requires(Container c) {
    std::begin(c);
    std::end(c);
    typename Container::value_type;
};

template <Iterable C>
auto to_vector(C&& container) {
    using T = typename std::remove_reference_t<C>::value_type;
    return std::vector<T>(std::begin(container), std::end(container));
}

//  Smart Pointers & Move Semantics 
class Resource {
public:
    explicit Resource(std::string name) : name_{std::move(name)} {
        std::cout << "Acquiring: " << name_ << '\n';
    }

    ~Resource() {
        std::cout << "Releasing: " << name_ << '\n';
    }

    Resource(const Resource&) = delete;
    Resource& operator=(const Resource&) = delete;
    Resource(Resource&&) = default;
    Resource& operator=(Resource&&) = default;

    std::string_view name() const noexcept { return name_; }

private:
    std::string name_;
};

//  Inheritance & Virtual 
class Shape {
public:
    virtual ~Shape() = default;

    NODISCARD virtual double area() const = 0;
    NODISCARD virtual double perimeter() const = 0;

    virtual std::string describe() const {
        return std::format("area={:.2f}, perimeter={:.2f}", area(), perimeter());
    }
};

class Circle final : public Shape {
public:
    explicit Circle(Point center, double radius) noexcept
        : center_{center}, radius_{radius} {}

    NODISCARD double area() const override {
        return PI * radius_ * radius_;
    }

    NODISCARD double perimeter() const override {
        return 2.0 * PI * radius_;
    }

private:
    Point center_;
    double radius_;
};

class Rectangle : public Shape {
public:
    Rectangle(double width, double height) noexcept
        : width_{width}, height_{height} {}

    NODISCARD double area() const override { return width_ * height_; }
    NODISCARD double perimeter() const override { return 2.0 * (width_ + height_); }

protected:
    double width_, height_;
};

//  Lambdas 
void demonstrate_lambdas() {
    auto add = [](int a, int b) -> int { return a + b; };
    auto multiply = [](int a, int b) noexcept { return a * b; };

    int offset = 10;
    auto add_offset = [offset](int x) { return x + offset; };

    // Mutable lambda
    int counter = 0;
    auto increment = [&counter]() mutable { return ++counter; };

    // Generic lambda (C++20)
    auto max_val = []<typename T>(T a, T b) { return a > b ? a : b; };

    // IIFE
    const auto result = [&]() {
        std::vector<int> nums{1, 2, 3, 4, 5};
        return std::accumulate(nums.begin(), nums.end(), 0);
    }();
}

//  Ranges 
void demonstrate_ranges() {
    using namespace std::views;

    std::vector<int> nums{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    auto pipeline = nums
        | filter([](int n) { return n % 2 == 0; })
        | transform([](int n) { return n * n; })
        | take(3);

    for (auto v : pipeline) {
        std::cout << v << ' ';
    }

    auto iota_range = iota(1) | take(5) | transform([](int n) { return n * n; });
}

//  Variant & Visit 
using Value = std::variant<int, double, std::string, bool>;

std::string visit_value(const Value& val) {
    return std::visit([](auto&& v) -> std::string {
        using T = std::decay_t<decltype(v)>;
        if constexpr (std::is_same_v<T, int>)
            return std::format("int:{}", v);
        else if constexpr (std::is_same_v<T, double>)
            return std::format("double:{:.2f}", v);
        else if constexpr (std::is_same_v<T, std::string>)
            return std::format("string:\"{}\"", v);
        else
            return std::format("bool:{}", v ? "true" : "false");
    }, val);
}

//  Main 
} // namespace yozakura

int main() {
    using namespace yozakura;

    // Points
    constexpr Point p1{0.0, 0.0};
    constexpr Point p2{3.0, 4.0};
    std::cout << std::format("Distance: {:.2f}\n", p1.distance(p2));

    // Shapes via unique_ptr
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(p1, 5.0));
    shapes.push_back(std::make_unique<Rectangle>(3.0, 4.0));

    for (const auto& s : shapes) {
        std::cout << s->describe() << '\n';
    }

    // Stack
    Stack<int> stack;
    stack.push(1);
    stack.push(2);
    stack.push(3);
    while (auto val = stack.pop()) {
        std::cout << *val << '\n';
    }

    // Variadic
    print("Hello", "World", 42, 3.14);
    constexpr auto total = sum(1, 2, 3, 4, 5);

    // Lambdas & ranges
    demonstrate_lambdas();
    demonstrate_ranges();

    // Variant
    Value v = std::string{"hello"};
    std::cout << visit_value(v) << '\n';

    return 0;
}

#endif // EXAMPLE_HPP
