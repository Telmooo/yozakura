// Yozakura - Go example
// These files are all gibberish, do not attempt to run them
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"math"
	"os"
	"sync"
	"time"
)

//  Constants 
const (
	maxRetries = 3
	appName    = "yozakura"
	version    = "1.0.0"
)

//  Custom Types & Errors 
type UserID string
type OrderID int64

var (
	ErrNotFound   = errors.New("not found")
	ErrValidation = errors.New("validation error")
	ErrTimeout    = errors.New("operation timed out")
)

type AppError struct {
	Code    string
	Message string
	Cause   error
}

func (e *AppError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("[%s] %s: %v", e.Code, e.Message, e.Cause)
	}
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error { return e.Cause }

func newNotFoundError(resource string, id any) *AppError {
	return &AppError{
		Code:    "NOT_FOUND",
		Message: fmt.Sprintf("%s with id %v not found", resource, id),
	}
}

//  Interfaces 
type Shape interface {
	Area() float64
	Perimeter() float64
	fmt.Stringer
}

type Repository[T any] interface {
	FindByID(ctx context.Context, id string) (T, error)
	FindAll(ctx context.Context) ([]T, error)
	Save(ctx context.Context, entity T) (T, error)
	Delete(ctx context.Context, id string) error
}

//  Structs 
type Point struct {
	X, Y float64
}

func NewPoint(x, y float64) Point {
	return Point{X: x, Y: y}
}

func (p Point) Distance(other Point) float64 {
	dx := p.X - other.X
	dy := p.Y - other.Y
	return math.Sqrt(dx*dx + dy*dy)
}

func (p Point) String() string {
	return fmt.Sprintf("(%.2f, %.2f)", p.X, p.Y)
}

//  Embedding 
type Animal struct {
	Name    string
	Species string
}

func (a Animal) Speak() string {
	return fmt.Sprintf("%s (%s) says hello", a.Name, a.Species)
}

type Dog struct {
	Animal // embedded struct
	Tricks []string
}

func (d *Dog) Learn(trick string) {
	d.Tricks = append(d.Tricks, trick)
}

func (d Dog) Perform() []string {
	result := make([]string, len(d.Tricks))
	for i, trick := range d.Tricks {
		result[i] = fmt.Sprintf("%s performs: %s", d.Name, trick)
	}
	return result
}

//  Shapes (implementing Shape interface) 
type Circle struct {
	Center Point
	Radius float64
}

func (c Circle) Area() float64      { return math.Pi * c.Radius * c.Radius }
func (c Circle) Perimeter() float64 { return 2 * math.Pi * c.Radius }
func (c Circle) String() string {
	return fmt.Sprintf("Circle(r=%.2f, area=%.2f)", c.Radius, c.Area())
}

type Rectangle struct {
	TopLeft     Point
	BottomRight Point
}

func (r Rectangle) Width() float64  { return r.BottomRight.X - r.TopLeft.X }
func (r Rectangle) Height() float64 { return r.BottomRight.Y - r.TopLeft.Y }
func (r Rectangle) Area() float64   { return r.Width() * r.Height() }
func (r Rectangle) Perimeter() float64 {
	return 2 * (r.Width() + r.Height())
}
func (r Rectangle) String() string {
	return fmt.Sprintf("Rect(%.2fx%.2f)", r.Width(), r.Height())
}

//  Generics 
type Set[T comparable] struct {
	items map[T]struct{}
}

func NewSet[T comparable](items ...T) *Set[T] {
	s := &Set[T]{items: make(map[T]struct{})}
	for _, item := range items {
		s.Add(item)
	}
	return s
}

func (s *Set[T]) Add(item T)      { s.items[item] = struct{}{} }
func (s *Set[T]) Remove(item T)   { delete(s.items, item) }
func (s *Set[T]) Contains(item T) bool { _, ok := s.items[item]; return ok }
func (s *Set[T]) Len() int        { return len(s.items) }

func Map[T, U any](slice []T, fn func(T) U) []U {
	result := make([]U, len(slice))
	for i, v := range slice {
		result[i] = fn(v)
	}
	return result
}

func Filter[T any](slice []T, predicate func(T) bool) []T {
	var result []T
	for _, v := range slice {
		if predicate(v) {
			result = append(result, v)
		}
	}
	return result
}

//  Goroutines & Channels 
func producer(ctx context.Context, nums []int) <-chan int {
	ch := make(chan int, len(nums))
	go func() {
		defer close(ch)
		for _, n := range nums {
			select {
			case <-ctx.Done():
				return
			case ch <- n:
			}
		}
	}()
	return ch
}

func fanOut(in <-chan int, workers int) []<-chan int {
	channels := make([]<-chan int, workers)
	for i := range workers {
		ch := make(chan int)
		channels[i] = ch
		go func() {
			defer close(ch)
			for v := range in {
				ch <- v * 2
			}
		}()
	}
	return channels
}

func merge(channels ...<-chan int) <-chan int {
	out := make(chan int)
	var wg sync.WaitGroup

	for _, ch := range channels {
		wg.Add(1)
		go func(c <-chan int) {
			defer wg.Done()
			for v := range c {
				out <- v
			}
		}(ch)
	}

	go func() {
		wg.Wait()
		close(out)
	}()

	return out
}

//  Defer 
func withDefer() error {
	f, err := os.Open("example.txt")
	if err != nil {
		return fmt.Errorf("open: %w", err)
	}
	defer f.Close() // guaranteed cleanup

	defer func() {
		if r := recover(); r != nil {
			fmt.Println("Recovered from panic:", r)
		}
	}()

	return nil
}

//  Variadic Functions 
func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func logWithFields(msg string, fields ...slog.Attr) {
	// variadic with typed args
	_ = fields
	fmt.Println(msg)
}

//  Type Assertions & Type Switches 
func describe(i interface{}) string {
	switch v := i.(type) {
	case int:
		return fmt.Sprintf("int: %d", v)
	case string:
		return fmt.Sprintf("string: %q (len=%d)", v, len(v))
	case bool:
		return fmt.Sprintf("bool: %v", v)
	case []int:
		return fmt.Sprintf("[]int: len=%d", len(v))
	case Shape:
		return fmt.Sprintf("Shape: %s", v)
	case nil:
		return "nil"
	default:
		return fmt.Sprintf("unknown: %T", v)
	}
}

//  Init 
func init() {
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	})))
}

//  Main 
func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	shapes := []Shape{
		Circle{Center: NewPoint(0, 0), Radius: 5},
		Rectangle{TopLeft: NewPoint(0, 4), BottomRight: NewPoint(3, 0)},
	}

	for _, s := range shapes {
		fmt.Printf("%s: area=%.2f\n", s, s.Area())
	}

	nums := []int{1, 2, 3, 4, 5}
	doubled := Map(nums, func(n int) int { return n * 2 })
	evens := Filter(nums, func(n int) bool { return n%2 == 0 })

	ch := producer(ctx, nums)
	for v := range ch {
		fmt.Println(v)
	}

	dog := &Dog{Animal: Animal{Name: "Rex", Species: "Canis"}}
	dog.Learn("sit").Learn("roll over")
	for _, trick := range dog.Perform() {
		slog.Info(trick)
	}

	fmt.Println(sum(1, 2, 3, 4, 5))
	fmt.Println(describe(42))
	fmt.Println(describe("hello"))

	_ = doubled
	_ = evens
}
