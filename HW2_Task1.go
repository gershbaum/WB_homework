package main

import (
	"fmt"
	"strings"
)

// 1. Создаем структуру Book, включающую название книги, автора, год издания и статус
type Book struct {
	Title  string
	Author string
	Year   int
	Status bool // true - доступна, false - на руках у читателя
}

// 2. Функция добавления новой книги
func addBook(book *[]Book, title, author string, year int) {
	newBook := Book{Title: title, Author: author, Year: year, Status: true}
	*book = append(*book, newBook)
	fmt.Printf("\nКнига '%s' добавлена!\n\n", title)
}

// 3. Метод для выдачи книги читателю (Issue())
func (book *Book) Issue() {
	if book.Status { // если книга доступна
		book.Status = false // выдаем книгу -> меняем статус
		fmt.Printf("Вам выдана книга '%s'.\n\n", book.Title)
	} else {
		fmt.Printf("К сожалению, книга '%s' недоступна. Она уже на руках у читателя.\n\n", book.Title)
	}
}

// 4. Метод для возврата книги (Return())
func (book *Book) Return() {
	if !book.Status { // если книга на руках
		book.Status = true // возвращаем книгу -> меняем статус
		fmt.Printf("Книга '%s' возвращена.\n\n", book.Title)
	} else {
		fmt.Printf("Книга '%s' уже в библиотеке.\n\n", book.Title)
	}
}

// 5. Функция для поиска книги по названию
func findBook(book []Book, title string) *Book {
	// Цикл для перебора всех книг без учета регистра с помощью пакета strings
	for i := range book {
		// сравниваем книги без учета регистра и по частичному совпадению
		if strings.EqualFold(book[i].Title, title) || strings.Contains(strings.ToLower(book[i].Title), strings.ToLower(title)) {
			return &book[i]
		}
	}
	return nil
}

// 6. Функция для вывода списка всех книг
func outputBooks(book []Book) {
	fmt.Println("Книги, которые можно взять в нашей библиотеке:")

	for _, b := range book {
		// изначально предполагаем, что книга доступна
		status := "Доступна"
		if !b.Status { // если недоступна
			status = "На руках у читателя"
		}
		fmt.Printf("Название: '%s', Автор: %s, Год издания: %d, Статус: %s\n", b.Title, b.Author, b.Year, status)
	}
}

func main() {
	// Зададим изначальный список книг
	book := []Book{
		{Title: "Защита Лужина", Author: "Набоков В.В.", Year: 1930, Status: true},
		{Title: "Доктор Живаго", Author: "Пастернак Б.Л.", Year: 1957, Status: true},
		{Title: "Собачье сердце", Author: "Булгаков М.А,", Year: 1925, Status: true},
	}

	// Выведем полный список
	outputBooks(book)

	// Найдем конкретную книгу
	query := "доктор"
	b := findBook(book, query)
	if b != nil { // есть ли такая книга?
		fmt.Printf("\nРезультаты поиска по запросу '%s': название - '%s', автор - %s, год издания - %d\n", query, b.Title, b.Author, b.Year)
	} else {
		fmt.Println("\nК сожалению, такой книги не нашлось :(")
	}

	// Добавим новую книгу
	addBook(&book, "Отцы и дети", "Тургенев И.С.", 1862)

	// Выдача книги
	if b != nil {
		b.Issue()
	} else {
		fmt.Println("К сожалению, этой книги у нас пока нет :(")
	}

	// Пробуем взять эту книгу еще раз
	if b != nil {
		b.Issue()
	} else {
		fmt.Println("К сожалению, этой книги у нас пока нет :(")
	}

	// Попробуем взять книгу, которой нет в библиотеке
	query = "Старуха Изергиль"
	c := findBook(book, query)
	if c != nil {
		c.Issue()
	} else {
		fmt.Printf("К сожалению, книги '%s' у нас пока нет :(\n\n", query)
	}

	// Возвращаем книгу
	if b != nil {
		b.Return()
	}

	if b != nil {
		b.Return()
	}

	// Вывод всех книг после проделанных операций
	outputBooks(book)
}
