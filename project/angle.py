import math

def is_inside_sector(mx, my, r, a, b, x, y):
    # Находим полярные координаты точки
    dx = x - mx
    dy = y - my
    distance = math.sqrt(dx**2 + dy**2)
    angle = math.atan2(dy, dx)
    angle = math.degrees(angle) % 360
    
    # Проверяем принадлежность сектору
    half_sector = b / 2
    lower_bound = (a - half_sector) % 360
    upper_bound = (a + half_sector) % 360
    
    return distance <= r and lower_bound <= angle <= upper_bound

# Константы
mx = -4  # Координата вершины сектора по x
my = 6  # Координата вершины сектора по y
r = 5   # Радиус сектора
a = 117  # Угол до биссектрисы сектора в градусах
b = 60  # Угол сектора в градусах

# Координаты точки для проверки
x = -5
y = 7

# Проверяем принадлежность точки сектору
if is_inside_sector(mx, my, r, a, b, x, y):
    print("Точка принадлежит сектору.")
else:
    print("Точка не принадлежит сектору.")
