import math

def find_slope_intercept(x1, y1, x2, y2):
    k = (y2 - y1) / (x2 - x1)
    b = y1 - k * x1
    return k, b

def find_intersection_point(k, b, center_x, center_y):
    x3 = - (b - (center_x / k) - center_y) / (k + 1 / k)
    y3 = k * x3 + b
    return x3, y3

def is_intersecting_line_circle(x1, y1, x2, y2, center_x, center_y, radius):
    k, b = find_slope_intercept(x1, y1, x2, y2)
    x3, y3 = find_intersection_point(k, b, center_x, center_y)
    distance = math.sqrt((x3 - center_x)**2 + (y3 - center_y)**2)
    return distance <= radius

# Пример использования
x1, y1 = 8.6, 5  # Координаты первой точки прямой
x2, y2 = 8, 6  # Координаты второй точки прямой
center_x, center_y = 8, 2  # Координаты центра окружности
radius = 2  # Радиус окружности

if is_intersecting_line_circle(x1, y1, x2, y2, center_x, center_y, radius):
    print("Прямая пересекает окружность")
else:
    print("Прямая не пересекает окружность")
