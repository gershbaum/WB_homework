package main

import (
	"fmt"
	"sync"
	"time"
)

// структура для сообщения
type Chat struct {
	Name    string // отправитель
	Message string // сообщение
}

// функция для отправки сообщений в канал
func user(name string, chat chan Chat, wg *sync.WaitGroup) {
	defer wg.Done()

	for i := 0; i < 4; i++ {
		c := Chat{
			Name:    name,
			Message: fmt.Sprintf("Message %d from %s\n", i, name),
		}
		chat <- c // Отправляем сообщение в канал
		time.Sleep(1 * time.Second)
	}
}

func main() {
	chat := make(chan Chat)
	wg := sync.WaitGroup{}

	users := []string{"Sergo", "Misha", "Dima"}

	for _, name := range users {
		wg.Add(1)                // увеличиваем счетчик на 1
		go user(name, chat, &wg) // запускаем горутину
	}

	go func() {
		wg.Wait() // ждем завершения горутин
		close(chat)
	}()

	for c := range chat {
		fmt.Printf("[%s]: %s", c.Name, c.Message)
	}
}
