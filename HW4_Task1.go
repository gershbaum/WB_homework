package main

import (
	"fmt"
	"strings"
)

// функция подсчета строк в строке. ch1 - канал для чтения, ch2 - канал для записи
func counter(ch1 <-chan string, ch2 chan<- int) {
	for str := range ch1 {
		ch2 <- len(strings.Fields(str))
	}
}

func main() {
	strings := []string{
		"my life my rules",
		"с новым годом",
		"горутина",
	}

	ch1 := make(chan string, len(strings))
	ch2 := make(chan int, len(strings))

	// Горутина для обработки строк
	go func() {
		defer close(ch2)
		counter(ch1, ch2)
	}()

	// Отправляем str в ch1
	go func() {
		defer close(ch1)
		for _, str := range strings {
			ch1 <- str
		}
	}()

	for i := 0; i < len(strings); i++ {
		fmt.Printf("Строка %d: %d слов(а)\n", i+1, <-ch2)
	}
}
