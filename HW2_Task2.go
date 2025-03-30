/*

Для реализации нам необходимо прописать несколько функций:

1. Добавление категорий и расходы по ним
2. Подсчет общей суммы расходов
3. Можно добавить отдельную функцию вывода всех расходов по категориям

*/

package main

import "fmt"

var m = make(map[string]float64) // мапа для хранения расходов по категориям

// 1. Функция добавления расходов (и автоматически категорий)
func addExpencesByCategory(category string, amount float64) {
	if _, exists := m[category]; exists {
		m[category] += amount // если категория уже существует, то расходы суммируются
	} else {
		m[category] = amount // если не существуетт, то создается автоматически
		fmt.Printf("Добавлена новая категория: '%s'\n", category)
	}
	fmt.Printf("В категорию '%s' добавлен расход на сумму %.3f\n\n", category, amount) // печатаем в любом случае
}

// 2. Фукция подсчета общей суммы расходов
func amountCalc() float64 {
	total := 0.0
	for _, amount := range m {
		total += amount
	}
	fmt.Printf("\nОбщая сумма расходов: %.3f", total)
	return total
}

// 3. Функция вывода всех расходов по категориям
func printExpencesByCategory() {
	fmt.Println("Расходы по категориям:")
	for category, amount := range m {
		fmt.Printf("В категории '%s' потрачено %.3f\n", category, amount)
	}
}

func main() {
	// Добавление расходов по категориям
	addExpencesByCategory("Продукты", 1000000.000)
	addExpencesByCategory("Рестораны", 20500.997)
	addExpencesByCategory("Рестораны", 29000.350)
	addExpencesByCategory("Траспорт", 5000.000)

	// Вывод всех расходов по категориям
	printExpencesByCategory()

	// Общая сумма расходов
	amountCalc()
}
