// Quiet Hacker - Java Preview
package com.quiethacker.examples;

import java.util.*;
import java.util.stream.*;
import java.util.concurrent.*;

public class Example {

    private static final int THREAD_POOL_SIZE = 4;

    public sealed interface Shape permits Circle, Rectangle {
        double area();
        String describe();
    }

    public record Circle(double radius) implements Shape {
        @Override
        public double area() {
            return Math.PI * radius * radius;
        }

        @Override
        public String describe() {
            return "Circle(r=%.2f)".formatted(radius);
        }
    }

    public record Rectangle(double width, double height) implements Shape {
        @Override
        public double area() {
            return width * height;
        }

        @Override
        public String describe() {
            return "Rect(%s x %s)".formatted(width, height);
        }
    }

    public static <T extends Shape> Map<String, Double> groupByType(List<T> shapes) {
        return shapes.stream()
            .collect(Collectors.groupingBy(
                s -> s.getClass().getSimpleName(),
                Collectors.summingDouble(Shape::area)
            ));
    }

    public static void main(String[] args) throws Exception {
        var shapes = List.of(
            new Circle(5.0),
            new Circle(3.0),
            new Rectangle(4.0, 6.0),
            new Rectangle(2.0, 8.0)
        );

        // Pattern matching with switch
        for (Shape shape : shapes) {
            String info = switch (shape) {
                case Circle c when c.radius() > 4 -> "Large " + c.describe();
                case Circle c -> "Small " + c.describe();
                case Rectangle r -> r.describe();
            };
            System.out.println(info + " -> area: " + shape.area());
        }

        // Parallel computation
        var executor = Executors.newFixedThreadPool(THREAD_POOL_SIZE);
        var futures = shapes.stream()
            .map(s -> executor.submit(() -> s.area()))
            .toList();

        double totalArea = 0;
        for (var future : futures) {
            totalArea += future.get();
        }

        System.out.printf("Total area: %.2f%n", totalArea);
        executor.shutdown();
    }
}
