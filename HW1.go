package main

import (
	"fmt"
)

func main() {

	// Задача 1
	numbers := []int{3, 5, 7, 2, 7, 8, 6, 4, 7, 0, 1, 7, 4, 8, 10, 3, 6, 8, 5, 4, 12, 3}
	sum := 0

	fmt.Println("Вывод к задаче 1.")
	fmt.Println("Исходный слайс:", numbers)

	for i, num := range numbers {
		if num%2 == 0 { // условие четности числа
			numbers[i] = 1 // если число четное, замеянем его на 1
		}

		sum += numbers[i] // подсчитываем сумму в цикле
	}

	fmt.Println("Новый слайс:", numbers)
	fmt.Println("Сумма чисел в новом слайсе:", sum)

	//_____________________________________________________________________________________
	// Задача 2

	numbers = make([]int, 10) // создаем пустой слайс

	for i := 0; i < len(numbers); i++ {
		numbers[i] = i + 1
	} // заполняем целыми числами от 1 до 10

	for i := 0; i < len(numbers); i++ {
		ptr := &numbers[i] // создаем указатель на элемент
		*ptr += 5          // с помощью указателя увеличиваем значение элемента слайса на 5
	}

	fmt.Println("\n\nВывод к задаче 2.")
	fmt.Println("Измененный слайс:", numbers)

	//_____________________________________________________________________________________
	// Задача 3
	numbers = []int{8, 44, 3, 5, 11, 8, 2, 10, 6, 77, 15, 12}
	min, max := -1, -1 // изначально задаем по -1, чтобы в дальнейшем провести проверку (для автоматизации)

	for _, num := range numbers {

		// прежде всего проверяем на четность
		if num%2 == 0 {

			// инициализируем min и max, если мы встретили четное число впервые
			if min == -1 && max == -1 {
				min, max = num, num
			}

			// поиск минимального четного числа
			if num < min {
				min = num
			}

			// поиск максимального четного числа
			if num > max {
				max = num
			}
		}
	}

	fmt.Println("\n\nВывод к задаче 3.")
	// проверка: встретилось ли хотя бы одно четное число или нет
	if max == -1 && min == -1 {
		fmt.Println("Четных чисел в слайсе нет")
	} else {
		fmt.Printf("Минимальное значение в слайсе, которое делится на 2 без остатка: %d\n", min)
		fmt.Printf("Максимальное значение в слайсе, которое делится на 2 без остатка: %d\n", max)
	}
}
