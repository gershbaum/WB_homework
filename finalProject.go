package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/joho/godotenv"
)

// структура для хранения статистики
type Stats struct {
	TotalRequests       int            `json:"total_requests"`        // общее число запросов
	PositiveResponses   int            `json:"positive_responses"`    // число положительных ответов
	NegativeResponses   int            `json:"negative_responses"`    // число отрицательных ответов
	ResponseStatusCount map[int]int    `json:"response_status_count"` // количество ответов по статусам
	ClientStats         map[string]int `json:"client_stats"`          // статистика по клиентам
}

// глобальные переменные для хранения статистики и ограничеия скорости
var (
	stats       Stats                    // статистика
	rateLimiter = make(chan struct{}, 5) // ограничение на 5 запросов в секунду
	serverURL   string                   // URL сервера
	statsMutex  sync.Mutex               // мьютекс для безопасного доступа к статистике
)

func init() {
	// подгружаем переменные из .env
	err := godotenv.Load("d:/ОБУЧЕНИЕ/WB Техношкола/7. GO/finalProject/.env")
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	// получаем порт из переменной окружения
	port := os.Getenv("PORT")

	// url сервера
	serverURL = fmt.Sprintf("http://localhost:%s", port)

	// статистика
	stats = Stats{
		ResponseStatusCount: make(map[int]int),    // инициализируем мапу для подсчета статусов
		ClientStats:         make(map[string]int), // мапа для статистики по клиентам
	}

	rand.Seed(time.Now().UnixNano()) // генератор случайных чисел
}

func main() {
	go startServer() // горутина для сервера
	time.Sleep(1 * time.Second)

	var wg sync.WaitGroup
	wg.Add(2)

	// запускаем клиентов в горутинах
	go client("Client1", &wg)
	go client("Client2", &wg)
	go serverChecker()

	wg.Wait() // ждем завершения работы клиентов

	// сохраяем статистику в JSON
	saveStatsToJSON()
}

// запуск сервера
func startServer() {
	http.HandleFunc("/", handleRequest)           // обработчик для всех запросов
	http.HandleFunc("/stats", handleStatsRequest) // обработчик для получения статистики

	port := os.Getenv("PORT")

	// запускаем сервер
	log.Printf("Server started on port %s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil)) // сервер не запускается -> программа завершается
}

// обработчик запросов на сервере
func handleRequest(w http.ResponseWriter, r *http.Request) {
	// смотрим, есть ли свободное место в лимитере
	select {
	case rateLimiter <- struct{}{}:
		defer func() { <-rateLimiter }() // освобождаем слот в канале после завершения обработки
	default:
		http.Error(w, "Request limit exceeded", http.StatusTooManyRequests) // если лимит превышен — ошибка
		return
	}

	// ограничение скорости (добавляем в канал rateLimiter)
	rateLimiter <- struct{}{}
	defer func() { <-rateLimiter }()

	// имитация обработки запроса
	time.Sleep(100 * time.Millisecond)

	// случайный выбор статуса ответа
	status := getRandomStatus()
	w.WriteHeader(status)

	// обновляем статистику
	statsMutex.Lock()
	stats.TotalRequests++               // увеличиваем общее количество запросов
	stats.ResponseStatusCount[status]++ // увеличиваем счетчик для текущего статуса
	if status == http.StatusOK || status == http.StatusAccepted {
		stats.PositiveResponses++
	} else {
		stats.NegativeResponses++
	}
	statsMutex.Unlock()

	// ответ клиенту
	fmt.Fprintf(w, "Response status: %d\n", status)
}

// обработчик запроса на получение статистики
func handleStatsRequest(w http.ResponseWriter, r *http.Request) {
	statsMutex.Lock()
	defer statsMutex.Unlock() // разблокируем доступ после завершения функции

	// преобразовываем статистику в json
	jsonData, err := json.MarshalIndent(stats, "", "  ")
	if err != nil {
		http.Error(w, "Failed to encode stats", http.StatusInternalServerError) // если ошибка, возвращаем Internal Server Error
		return
	}

	// отправляем json клиенту
	w.Header().Set("Content-Type", "application/json") // заголовок
	w.Write(jsonData)                                  // отправка данных
}

// получения случайного статуса ответа
func getRandomStatus() int {
	random := rand.Intn(100)

	if random < 70 {
		// 70% положительных ответов
		if rand.Intn(2) == 0 {
			return http.StatusOK
		}
		return http.StatusAccepted
	} else {
		// 30% отрицательных ответов
		if rand.Intn(2) == 0 {
			return http.StatusBadRequest
		}
		return http.StatusInternalServerError
	}
}

// клиент
func client(name string, wg *sync.WaitGroup) {
	defer wg.Done() // уменьшаем счетчик WaitGroup при завершении работы клиента

	// клиенты 1 и 2 отправляют по 100 post запросов
	var clientWg sync.WaitGroup // WaitGroup для воркеров
	clientWg.Add(2)             // 2 воркера

	ticker := time.NewTicker(200 * time.Millisecond)
	defer ticker.Stop()

	for i := 0; i < 2; i++ {
		go func(workerID int) {
			defer clientWg.Done() // уменьшаем счетчик WaitGroup при завершении работы воркера

			for j := 0; j < 50; j++ {
				// ограничение скорости (5 запросов в секунду)
				<-ticker.C

				// отправка POST-запроса
				resp, err := http.Post(serverURL, "text/plain", nil)
				if err != nil {
					log.Printf("%s: Worker %d: Request failed: %s\n", name, workerID, err)
					continue
				}

				// обовляем статистику клиента
				statsMutex.Lock()
				stats.ClientStats[name]++ // увеличиваем счетчик запросов для текущего клиента
				statsMutex.Unlock()

				log.Printf("%s: Worker %d: Response status: %d\n", name, workerID, resp.StatusCode)
				resp.Body.Close() // закрываем тело ответа
			}
		}(i)
	}

	clientWg.Wait()                                                             // ожидаем завершения работы всех воркеров
	log.Printf("%s: Done. Total requests: %d\n", name, stats.ClientStats[name]) // и логируем завершение работы клиента
}

func serverChecker() {
	for {
		resp, err := http.Get(serverURL) // get-запрос
		if err != nil {                  // если сервер недоступен
			log.Printf("Client3: Server is down")
		} else { // если доступен
			log.Printf("Client3: Server is up, status: %d\n", resp.StatusCode)
			resp.Body.Close()
		}
		time.Sleep(5 * time.Second) // 5 секунд перед следующей проверкой
	}
}

// сохранение статистики в json
func saveStatsToJSON() {
	statsMutex.Lock()
	defer statsMutex.Unlock()

	// преобразовываем статистику в json с отступами
	jsonData, err := json.MarshalIndent(stats, "", "  ")
	if err != nil {
		log.Fatalf("Failed to encode stats to JSON: %s", err) // ошибка -> завершение программы
	}

	// сохраняем json в файл
	err = os.WriteFile("stats.json", jsonData, 0644)
	if err != nil {
		log.Fatalf("Failed to write stats to file: %s", err) // ошибка -> завершение программы
	}

	log.Println("Stats saved to stats.json") // и логируем сохранение
}
