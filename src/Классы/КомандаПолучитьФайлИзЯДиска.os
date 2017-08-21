
///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем OAuth_Токен;

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Получить файл из Yandex-Диск");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-path",
		"Путь к локальному каталогу для сохранения загруженных файлов");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-token",
		"Token авторизации");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-file",
		"Путь к файлу на Yandex-Диск для загрузки");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-list",
		"Путь к файлу на Yandex-Диск со списком файлов,
		|которые будут загружены (параметр -ya-file игнорируется)");

	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, 
		"-delsource",
		"Удалить файл после получения");

	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры

Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
	ЭтоСписокФайлов = Истина;
	
	ЦелевойПуть				= ПараметрыКоманды["-path"];
	OAuth_Токен				= ПараметрыКоманды["-ya-token"];

	ПутьНаДиске				= ПараметрыКоманды["-ya-list"];
	Если НЕ ЗначениеЗаполнено(ПутьНаДиске) Тогда
		ПутьНаДиске				= ПараметрыКоманды["-ya-file"];
		ЭтоСписокФайлов	= Ложь;
	КонецЕсли;

	УдалитьИсточник			= ПараметрыКоманды["-delsource"];

	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();

	Если ПустаяСтрока(ЦелевойПуть) Тогда
		Лог.Ошибка("Не указана путь к каталогу для сохранения загруженных файлов");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ПустаяСтрока(OAuth_Токен) Тогда
		Лог.Ошибка("Не задан Token авторизации");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ПустаяСтрока(ПутьНаДиске) Тогда
		Лог.Ошибка("Не задан путь к файлу для получения из Yandex-Диск");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	ЯндексДиск = Неопределено;
	МассивПолучаемыхФайлов = Новый Массив;
	
	Попытка

		Лог.Информация("ПутьНаДиске %1", ПутьНаДиске);
		Лог.Информация("ЦелевойПуть %1", ЦелевойПуть);
		ПутьКСкачанномуФайлу = ПолучитьФайлИзЯДиска(ЯндексДиск, ПутьНаДиске, ЦелевойПуть);
		Лог.Информация("ПутьКСкачанномуФайлу %1", ПутьКСкачанномуФайлу);
	
		ФайлИнфо = Новый Файл(ПутьКСкачанномуФайлу);

		КаталогНаДиске = СтрЗаменить(ПутьНаДиске, ФайлИнфо.Имя, "");
	
		Если ЭтоСписокФайлов Тогда
	
			// открываем и читаем построчно исходный файл
			ЧтениеСписка = Новый ЧтениеТекста(ПутьКСкачанномуФайлу, КодировкаТекста.UTF8);
			СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
			Пока СтрокаСписка <> Неопределено Цикл
				Если ЗначениеЗаполнено(СокрЛП(СтрокаСписка)) Тогда
					МассивПолучаемыхФайлов.Добавить(КаталогНаДиске + СтрокаСписка);
				КонецЕсли;
				
				СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
			КонецЦикла;
			
			ЧтениеСписка.Закрыть();

		КонецЕсли;

		Для Каждого ПолучаемыйФайл ИЗ МассивПолучаемыхФайлов Цикл
			
			ПутьКСкачанномуФайлу = ПолучитьФайлИзЯДиска(ЯндексДиск, ПолучаемыйФайл, ЦелевойПуть, УдалитьИсточник);

		КонецЦикла;
		
		Возврат ВозможныйРезультат.Успех;
	Исключение
		Лог.Ошибка(ОписаниеОшибки());
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецПопытки;

КонецФункции

// Функция получения файла из Я-Диска
Функция ПолучитьФайлИзЯДиска(ЯДиск = Неопределено, Знач ПутьНаДиске, Знач ЦелевойПуть, УдалитьИсточник = Ложь)
	
	Если ЯДиск = Неопределено Тогда
		
		ЯДиск = Новый ЯндексДиск;
		ЯДиск.УстановитьТокенАвторизации(OAuth_Токен);
	КонецЕсли;
	
	ПутьКСкачанномуФайлу = "";
	Лог.Информация("ПутьНаДиске %1", ПутьНаДиске);
	Лог.Информация("ЦелевойПуть %1", ЦелевойПуть);
	
	Попытка
		ПутьКСкачанномуФайлу = ЯДиск.СкачатьФайлСДиска(ЦелевойПуть, ПутьНаДиске, Истина);

		Лог.Информация("Файл получен %1", ПутьКСкачанномуФайлу);
	Исключение
		Лог.Ошибка("Ошибка получения файла %1: %2", ПутьНаДиске, ИнформацияОбОшибке());
	КонецПопытки;

	Если УдалитьИсточник Тогда
		ЯДиск.Удалить(ПутьНаДиске, Истина);
		СвойстваДиска = ЯДиск.ПолучитьСвойстваДиска();
		Лог.Информация(СтрШаблон("Удален файл на Yandex-Диск %1", ПутьНаДиске));
		Лог.Отладка(СтрШаблон("Всего доступно %1 байт", СвойстваДиска.total_space));
		Лог.Отладка(СтрШаблон("Из них занято %1 байт", СвойстваДиска.used_space));
	КонецЕсли;
	
	Возврат ПутьКСкачанномуФайлу;

КонецФункции // ОтправитьФайлНаЯДиск()

Лог = Логирование.ПолучитьЛог("ktb.app.cpdb");