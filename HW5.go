package main

import (
	"encoding/json"
	"net/http"

	"github.com/sirupsen/logrus"
)

// структура Student будет содержать инф-цию о стедентах и их баллах
type Student struct {
	FullName         string `json:"fullName"`
	MathScore        int    `json:"mathScore"`
	InformaticsScore int    `json:"informaticsScore"`
	EnglishScore     int    `json:"englishScore"`
}

// слайс для храенения инф-ции о поступивших студентах
var (
	admittedStudents []Student      // слайс для храенения инф-ции о поступивших студентах
	log              = logrus.New() // настройка логгера logrus
)

func main() {
	initializeStudents()

	http.HandleFunc("/apply", applyHandler)       // обработка заявок
	http.HandleFunc("/admitted", admittedHandler) // вывод поступивших студентов

	log.Info("Сервер запускается на порту :8080") // логируем запуск сервера

	// запуск сервера
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal(err)
	}
}

// три студента с заранее определенными баллами
func initializeStudents() {
	admittedStudents = []Student{
		{FullName: "Сергей Гершбаум", MathScore: 5, InformaticsScore: 5, EnglishScore: 5},
		{FullName: "Ольга Петрова", MathScore: 5, InformaticsScore: 5, EnglishScore: 5},
		{FullName: "Егор Крид", MathScore: 2, InformaticsScore: 2, EnglishScore: 2},
	}

	log.WithFields(logrus.Fields{
		"students": admittedStudents,
	}).Info("Список студентов инициализирован")
}

// обработчик для поступления
func applyHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		handleApplyPost(w, r) // вызов функции обработки post-запроса
	default:
		handleInvalidMethod(w, r) // вызов функции обработки некорректного метода
	}
}

// обработчик для вывода поступивших студентов
func admittedHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet { //проверка метода
		handleAdmittedGet(w) // вызов функции обработки get-запроса
	} else {
		handleInvalidMethod(w, r) // вызов функции обработки некорректного метода
	}
}

// функция обработки post-запроса на /apply
func handleApplyPost(w http.ResponseWriter, r *http.Request) {
	var s Student
	err := json.NewDecoder(r.Body).Decode(&s) // декодируем JSON из запроса
	if err != nil {
		log.WithFields(logrus.Fields{
			"error": err.Error(),
		}).Error("Не удалось декодировать данные студента")
		http.Error(w, "Данные некорректны", http.StatusBadRequest)
		return
	}

	// Проверка суммы баллов
	totalScore := s.MathScore + s.InformaticsScore + s.EnglishScore
	if totalScore >= 14 {
		admittedStudents = append(admittedStudents, s)
		log.WithFields(logrus.Fields{
			"student": s.FullName,
			"score":   totalScore,
		}).Info("Студент поступил")
		w.WriteHeader(http.StatusCreated)
		w.Write([]byte("Заявка принята: студет поступил"))
	} else {
		log.WithFields(logrus.Fields{
			"student": s.FullName,
			"score":   totalScore,
		}).Warn("К сожалению, для поступления баллов недостаточно")
		http.Error(w, "Студент не поступил", http.StatusBadRequest)
	}
}

// функция обработки get-запроса на /admitted
func handleAdmittedGet(w http.ResponseWriter) {
	err := json.NewEncoder(w).Encode(admittedStudents) // кодируем список поступивших в json
	if err != nil {
		log.WithFields(logrus.Fields{
			"error": err.Error(),
		}).Error("Ошибка при попытке закодировать список поступивших")
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Info("Список поступивших студентов успешно возвращен")
}

// функция обработки некорректного метода
func handleInvalidMethod(w http.ResponseWriter, r *http.Request) {
	log.WithFields(logrus.Fields{
		"method": r.Method,
		"url":    r.URL,
	}).Warn("Метод не поддерживается")
	http.Error(w, "Метод не поддерживается", http.StatusMethodNotAllowed)
}
