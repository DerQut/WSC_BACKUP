`timescale 1ns / 1ps

/*

Autor:		Marcel Cholodecki
Indeks:		275818
Kierunek:	Inteligentna Elektronika
Data:			03.02.2025
Uklad:		Automat sprzedajacy napoje (Testbench)

*/

module napoje_beh_test;

	// Wejscia ukladu
	reg user_ok;
	reg user_break;
	reg user_sel;
	reg clk;
	reg reset;
	reg nr_w;
	reg [2:0] adres;
	reg [7:0] dane_we;
	reg moneta_in;
	
	// Wyjscia ukladu
	wire [7:0] dane_wy;
	wire podajnik_trig;
	wire [1:0] nr_podajnika;
	wire reszta_out;
	
	// Deklaracja stalych
	//
	// Okres zegarowy: 10 ns
	localparam CLK_PERIOD = 			4'b1010;
	//
	// Adresy rejestrow ukladu
	localparam KAWA_ile_adr = 			3'b001;
	localparam HERB_ile_adr = 			3'b010;
	localparam SOK_ile_adr = 			3'b011;
	localparam KAWA_cena_adr = 		3'b101;
	localparam HERB_cena_adr = 		3'b110;
	localparam SOK_cena_adr = 			3'b111;
	localparam STAN_adr = 				3'b000;
	localparam MONETY_ile_adr = 		3'b100;
	//
	// Tryby pracy nr_w
	localparam READ = 					1'b0;
	localparam WRITE = 					1'b1;
	//
	// Poczatkowe wartosci ilosci napojow
	localparam KAWA_ile_initial = 	8'b100;
	localparam HERB_ile_initial = 	8'b11;
	localparam SOK_ile_initial = 		8'b1;
	//
	// Poczatkowe wartosci ceny napojow
	localparam KAWA_cena_initial = 	8'b11;
	localparam HERB_cena_initial = 	8'b10;
	localparam SOK_cena_initial = 	8'b1;
	//
	// Stany wewnetrzne maszyny stanow
	localparam STATE_Reset = 			3'b000;
	localparam STATE_Wybor = 			3'b001;
	localparam STATE_Moc = 				3'b011;
	localparam STATE_Platnosc = 		3'b010;
	localparam STATE_Przygotowanie = 3'b110;
	localparam STATE_Reszta = 			3'b100;
	//
	// Numery podajnika odpowiadajace napojom
	localparam KAWA_type = 2'b01;
	localparam HERB_type = 2'b10;
	localparam SOK_type = 2'b11;
	
	// Licznik dozowan porcji napoju
	integer podajnik_trig_count =		0;
	
	// Licznik wrzuconych monet
	integer moneta_in_count =			0;

	// Instantiate the Unit Under Test (UUT)
	napoje_beh uut (
		.user_ok(user_ok), 
		.user_break(user_break), 
		.user_sel(user_sel), 
		.clk(clk), 
		.reset(reset), 
		.nr_w(nr_w), 
		.adres(adres), 
		.dane_we(dane_we), 
		.dane_wy(dane_wy), 
		.moneta_in(moneta_in), 
		.podajnik_trig(podajnik_trig), 
		.nr_podajnika(nr_podajnika), 
		.reszta_out(reszta_out)
	);
	
	// Deklaracja procesu takta zegarowego
	always begin
		#(CLK_PERIOD * 0.5);
		clk = ~clk;
	end
	
	
	// Czyszczenie linii dane_we przy przejsciu w tryb odczytu
	always @(negedge nr_w) begin
		dane_we = 8'b0;
	end
	
	
	// Zliczanie dozowan porcji napoju
	always @(posedge podajnik_trig) begin
		podajnik_trig_count = podajnik_trig_count + 1;
	end
	
	
	// Zliczanie wrzuconych monet
	always @(posedge moneta_in) begin
		moneta_in_count = moneta_in_count + 1;
		$display("%d ns: Wrzucono monete nr %d", $time, moneta_in_count);
	end
	
	
	// Zerowanie licznikow po wykryciu stanu STATE_Reszta
	always @(negedge reszta_out) begin
		moneta_in_count = 0;
		podajnik_trig_count = 0;
	end
	
	
	// Zerowanie licznikow po wyzwoleniu Reset
	always @reset begin
		if (reset == 1) begin
			moneta_in_count = 0;
			podajnik_trig_count = 0;
		end
	end
	
	
	// Zapis informacji o wcisnieciu przycisku OK do konsoli
	always @(posedge user_ok) begin
		$display("%d ns: Wcisniecie przycisku OK", $time);
	end
	
	
	// Zapis informacji o wcisnieciu przycisku BREAK do konsoli
	always @(posedge user_break) begin
		$display("%d ns: Wcisniecie przycisku BREAK", $time);
	end
	
	
	// Zapis informacji o wcisnieciu przycisku SELECT do konsoli
	always @(posedge user_sel) begin
		$display("%d ns: Wcisniecie przycisku SELECT", $time);
	end
	
	
	// Glowny proces symulacji
	initial begin
		
		// Sledzenie wejscia Reset na konsoli
		$monitor("%d ns: Zmiana wartosci Reset na %d", $time, reset);
	
		// Inicjalizacja wejsc
		user_ok = 0;
		user_break = 0;
		user_sel = 0;
		reset = 0;
		clk = 0;
		nr_w = 0;
		adres = 0;
		dane_we = 0;
		moneta_in = 0;
		
		// Wlaczenie RESET na czas jednego cylku CLK
		reset = 1;
		#(CLK_PERIOD/2);
		reset = 0;

// Test 1: Zapis i odczyt wartosci z rejestrow 

		$display("\nTest 1: Zapis i odczyt wartosci z rejestrow");

		// Zapisanie nowej ilosci kawy (4)
		writeToRegister(adres, KAWA_ile_adr, dane_we, KAWA_ile_initial, nr_w);
		#CLK_PERIOD;
		
		// Zapisanie nowej ilosci herbaty (3)
		writeToRegister(adres, HERB_ile_adr, dane_we, HERB_ile_initial, nr_w);
		#CLK_PERIOD;
		
		// Zapisanie nowej ilosci soku (1)
		writeToRegister(adres, SOK_ile_adr, dane_we, SOK_ile_initial, nr_w);
		#CLK_PERIOD;
		
		
		// Odcztanie i weryfikacja nowej ilosci kawy
		readFromRegister(adres, KAWA_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("KAWA_ile", dane_wy, KAWA_ile_initial);
		
		// Odcztanie i weryfikacja nowej ilosci herbaty
		readFromRegister(adres, HERB_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("HERB_ile", dane_wy, HERB_ile_initial);
		
		// Odcztanie i weryfikacja nowej ilosci soku
		readFromRegister(adres, SOK_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("SOK_ile", dane_wy, SOK_ile_initial);
		
		
		// Zapis wartosci cen do rejestrow
		writeToRegister(adres, KAWA_cena_adr, dane_we, KAWA_cena_initial, nr_w);
		#CLK_PERIOD;
		writeToRegister(adres, HERB_cena_adr, dane_we, HERB_cena_initial, nr_w);
		#CLK_PERIOD;
		writeToRegister(adres, SOK_cena_adr, dane_we, SOK_cena_initial, nr_w);
		#CLK_PERIOD;
		
		// Weryfilacja wartosci cen
		readFromRegister(adres, KAWA_cena_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("KAWA_cena", dane_wy, KAWA_cena_initial);
		
		readFromRegister(adres, HERB_cena_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("HERB_cena", dane_wy, HERB_cena_initial);
		
		readFromRegister(adres, SOK_cena_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("SOK_cena", dane_wy, SOK_cena_initial);
		
// Test 2: Kupno domyslnego napoju (kawy) z domyslna moca (1), wrzucajac wyliczona ilosc monet
		
		$display("\nTest 2: Zakup domyslnego napoju z dokladnie wyliczona liczba monet");
		
		// Rozpoczecie sledzenia stanu wewnetrznego maszyny stanow
		readFromRegister(adres, STAN_adr, nr_w);
		#CLK_PERIOD;
		
		// Weryfikacja stanu maszyny (oczekiwany STATE_Wybor)
		assertMachineState(dane_wy, STATE_Wybor);
		#CLK_PERIOD;
		
		// Przejscie do nastepnego stanu maszyny, wciskajac przycisk OK
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#CLK_PERIOD;
		
		// Weryfikacja stanu maszyny (oczekiwany STATE_Moc)
		assertMachineState(dane_wy, STATE_Moc);
		#CLK_PERIOD;
		
		// Przejscie do nastepnego stanu maszyny, wciskajac przycisk OK
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#CLK_PERIOD;
		
		// Weryfikacja stanu maszyny (oczekiwany STATE_Platnosc)
		assertMachineState(dane_wy, STATE_Platnosc);
		#CLK_PERIOD;
		
		// Wrzucenie odpowiedniej liczby monet (rownej cenie kawy)
		while (moneta_in_count < KAWA_cena_initial)
		begin
			moneta_in = 1;
			#CLK_PERIOD;
			moneta_in = 0;
			#CLK_PERIOD;
		end
		
		// Odczyt i weryfikacja liczby monet z rejestru MONETY_ile
		readFromRegister(adres, MONETY_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("MONETY_ile", dane_wy, KAWA_cena_initial);
		
		// Sledzenie stanu maszyny
		readFromRegister(adres, STAN_adr, nr_w);
		#CLK_PERIOD;
		
		// Przejscie do nastepnego stanu maszyny, wciskajac przycisk OK
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#CLK_PERIOD;
		
		// Weryfikacja stanu maszyny (oczekiwany STATE_Przygotowanie)
		assertMachineState(dane_wy, STATE_Przygotowanie);
		
		// Odczekanie do skonczenia przygotowania napoju
		#(CLK_PERIOD*3);
		
		// Weryfikacja parametrow otrzymanego napoju (rodzaj, moc)
		assertBeverageType(nr_podajnika, KAWA_type);
		assertBeverageStrength(podajnik_trig_count, 1);
		
		// Weryfikacja nastepnego stanu maszyny (oczekiwany STATE_Reszta)
		#CLK_PERIOD;
		assertMachineState(dane_wy, STATE_Reszta);
		
		// Weryfikacja nastepnego stanu maszyny (oczekiwany STATE_Wybor)
		#CLK_PERIOD;
		assertMachineState(dane_wy, STATE_Wybor);
		
		// Weryfikacja wyzerowania rejestru MONETY_ile
		readFromRegister(adres, MONETY_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("MONETY_ile", dane_wy, moneta_in_count);
		
		// Weryfikacja stanu zasobnika
		readFromRegister(adres, KAWA_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("KAWA_ile", dane_wy, KAWA_ile_initial-1);
		// ^ BLAD ^ Uzyskanie wartosci ujemnej
		
		
// Test 3: Zakup soku o intensywnosci napoju wiekszej od stanu zasobnika

		$display("\nTest 3: Zakup soku o intensywnosci napoju wiekszej od stanu zasobnika");
		
		// Odczyt wartosci zasobnika dla soku
		readFromRegister(adres, SOK_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("SOK_ile", dane_wy, SOK_ile_initial);
		
		// Odczyt obecnego stanu automatu (oczekiwany STATE_Wybor)
		readFromRegister(adres, STAN_adr, nr_w);
		#CLK_PERIOD;
		assertMachineState(dane_wy, STATE_Wybor);
		
		// Wybor soku
		user_sel = 1;
		#CLK_PERIOD;
		user_sel = 0;
		#CLK_PERIOD;
		user_sel = 1;
		#CLK_PERIOD;
		user_sel = 0;
		#CLK_PERIOD;
		
		// Zatwierdzenie wyboru
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#CLK_PERIOD;
		
		// Weryfikacja obecnego stanu automatu (oczekiwany STATE_Moc)
		assertMachineState(dane_wy, STATE_Moc);
		
		// Wybor maksymalnej intensywnosci napoju
		user_sel = 1;
		#CLK_PERIOD;
		user_sel = 0;
		#CLK_PERIOD;
		user_sel = 1;
		#CLK_PERIOD;
		user_sel = 0;
		#CLK_PERIOD;
		
		// Zatwierdzenie wyboru
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#CLK_PERIOD;
		
		// Weryfikacja obecnego stanu automatu (oczekiwany STATE_Wybor)
		#(CLK_PERIOD*3);
		assertMachineState(dane_wy, STATE_Wybor);
		// ^ BLAD ^ : Stan = STATE_Platnosc
		
		// Proba zakupu pomimo braku wystarczajacej ilosci soku w zasobniku
		while (moneta_in_count < SOK_cena_initial)
		begin
			moneta_in = 1;
			#CLK_PERIOD;
			moneta_in = 0;
			#CLK_PERIOD;
		end
		
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		
		#(3*CLK_PERIOD);
		
		// Sprawdzenie obecnego stanu maszyny (po wrzuceniu monet oczekiwany stan STATE_Przygotowanie)
		assertMachineState(dane_wy, STATE_Przygotowanie);
		// ^ Pomimo wrzucenia wystarczajacej ilosci monet, automat nie przechodzi do stanu STATE_Przygotowanie)
		
		// Odczyt ilosci monet w automacie
		readFromRegister(adres, MONETY_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("MONETY_ile", dane_wy, SOK_cena_initial);
		
		// Powrot do menu wyboru napoju
		user_break = 1;
		#CLK_PERIOD;
		user_break = 0;
		
		readFromRegister(adres, STAN_adr, nr_w);
		#CLK_PERIOD;
		
		// Sprawdzenie obecnego stanu maszyny (oczekiwany STATE_Reszta)
		assertMachineState(dane_wy, STATE_Reszta);
		
		// Sprawdzenie wyzerowania ilosci monet w automacie
		readFromRegister(adres, MONETY_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("MONETY_ile", dane_wy, 0);
		
		// Sprawdzenie stanu maszyny (oczekiwany STATE_Wybor)
		readFromRegister(adres, STAN_adr, nr_w);
		#CLK_PERIOD;
		assertMachineState(dane_wy, STATE_Wybor);
		
		// Weryfikacja stanu zasobnika
		readFromRegister(adres, SOK_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("SOK_ile", dane_wy, SOK_ile_initial);
		// ^ BLAD ^ Uzyskanie wartosci ujemnej
		
		
// Test 4: Zakup herbaty przy wrzuceniu zbyt malej ilosci monet

		$display("\nTest 4: Zakup herbaty przy wrzuceniu zbyt malej ilosci monet");
		
		// Potwierdzenie ceny herbaty (2 monety)
		readFromRegister(adres, HERB_cena_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("HERB_cena", dane_wy, 2);
		
		// Sprawdzenie stanu maszyny (oczekiwany STATE_Wybor)
		readFromRegister(adres, STAN_adr, nr_w);
		#CLK_PERIOD;
		assertMachineState(dane_wy, STATE_Wybor);
		
		// Wybranie napoju (Herbaty)
		user_sel = 1;
		#CLK_PERIOD;
		user_sel = 0;
		#CLK_PERIOD;
		user_sel = 1;
		#CLK_PERIOD;
		user_sel = 0;
		#(2*CLK_PERIOD);
		
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#(2*CLK_PERIOD);
		
		// Sprawdzenie stanu maszyny (oczekiwany STATE_Moc)
		assertMachineState(dane_wy, STATE_Moc);
		
		// Wybranie domyslnej mocy napoju
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#(CLK_PERIOD*2);
		
		// Sprawdzenie stanu maszyny (oczekiwany STATE_Platnosc)
		assertMachineState(dane_wy, STATE_Platnosc);
		
		// Wrzucenie jednej monety
		moneta_in = 1;
		#CLK_PERIOD;
		moneta_in = 0;
		#CLK_PERIOD;
		
		// Weryfikacja zawartosci rejestru MONETY_ile
		readFromRegister(adres, MONETY_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("MONETY_ile", dane_wy, 1);
		
		// Sledzenie stanu maszyny
		readFromRegister(adres, STAN_adr, nr_w);
		
		// Proba przejscia do nastepnego stanu (oczekiwany STATE_Platnosc)
		user_ok = 1;
		#CLK_PERIOD;
		user_ok = 0;
		#(2*CLK_PERIOD);
		assertMachineState(dane_wy, STATE_Platnosc);
		
		// Proba anulowania zamowienia
		user_break = 1;
		#CLK_PERIOD;
		user_break = 0;
		#CLK_PERIOD
		
		// Weryfikacja stanu automatu (oczekiwany STATE_Reszta)
		assertMachineState(dane_wy, STATE_Reszta);
		#CLK_PERIOD;
		
		// Weryfikacja nastepnego stanu automatu (oczekiwany STATE_Wybor)
		assertMachineState(dane_wy, STATE_Wybor);
		#CLK_PERIOD;
		
		// Weryfikacja wydania reszty
		readFromRegister(adres, MONETY_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("MONETY_ile", dane_wy, 0);
		#CLK_PERIOD;
		
		// Weryfikacja stanu zasobnika
		readFromRegister(adres, HERB_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("HERB_ile", dane_wy, HERB_ile_initial);
		// ^ BLAD ^ Uzyskanie wartosci ujemnej
		

// Test 5: Weryfikacja poprawnosci dzialania Reset
		
		$display("\nTest 5: Weryfikacja poprawnosci dzialania stanu Reset");
		
		reset = 1;
		#CLK_PERIOD;
		assertMachineState(dane_wy, STATE_Reset);
		// ^ BLAD ^ : wartosc rejestru STAN nie przyjmuje wartosci 3'b000 (STATE_Reset) po wywolaniu resetu (sprzeczonosc z grafem przejsc)
		
		reset = 0;
		#CLK_PERIOD;
		
		// Weryfikacja wyzerowania wszystkich rejestrow ukladu
		readFromRegister(adres, KAWA_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("KAWA_ile", dane_wy, 0);
		
		readFromRegister(adres, HERB_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("HERB_ile", dane_wy, 0);
		
		readFromRegister(adres, SOK_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("SOK_ile", dane_wy, 0);
		
		
		readFromRegister(adres, KAWA_cena_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("KAWA_cena", dane_wy, 0);
		
		readFromRegister(adres, HERB_cena_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("HERB_cena", dane_wy, 0);
		
		readFromRegister(adres, SOK_cena_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("SOK_cena", dane_wy, 0);
		
		
		readFromRegister(adres, MONETY_ile_adr, nr_w);
		#CLK_PERIOD;
		assertRegisterReadout("MONETY_ile", dane_wy, 0);
		
		// Zakonczenie symulacji
		#CLK_PERIOD;
		$stop;

	end
	
	
	// Zadanie zapisu danych do okreslonego rejestru
	task writeToRegister;
		output[2:0] adres;	// Wejscie ukladu (adres rejestru)
		input[2:0] adresNew;	// Wartosc adresu rejestru
		output[7:0] dane;		// Wejscie ukladu (data_we)
		input[7:0] daneNew;	// Wartosc zapisywanych danych
		output nr_w;			// Wejscie ukladu (nr_w) - wymuszenie wartosci WRITE
		
		begin
			nr_w = WRITE;		// Przypisanie wartosci WRITE na wejscie ukladu
			adres = adresNew;	// Przypisanie nowej wartosci adresu na wejscie ukladu
			dane = daneNew;	// Przypisanie nowej wartosci danych na wejscie ukladu
		end
	endtask
	
	
	// Zadanie odczytu danych z okreslonego rejestru
	task readFromRegister;
		output[2:0] adres;	// Wejscie ukladu (adres rejestru)
		input[2:0] adresNew;	// Wartosc adresu rejestru
		output nr_w;			// Wejscie ukladu (nr_w) - wymuszenie wartosci READ
		
		begin
			nr_w = READ;		// Przypisanie wartosci READ na wejscie ukladu
			adres = adresNew;	// Przypisanie nowej wartosci adresu na wejscie ukladu
		end
	endtask
	
	
	// Zadanie ostrzezenia o nieprawidlowym zapisie do rejestru
	task assertRegisterReadout;
		input[16*8:1] registerName;	// Nazwa rejestru w formacie string, zawarta w wyswietlanej wiadomosci
		input[7:0] obtained;				// Odczytana wartosc z rejestru (w zalozeniu reg dane_wy)
		input[7:0] expected;				// Oczekiwana wartosc
		
		begin
			if (obtained == expected) begin
				$display("%d ns: Zawartosc rejestru [%s]  prawidlowa (%d)", $time, registerName, obtained);
			end else begin
				$display("%d ns: Nieprawidlowa zawartosc rejestru [%s]. Oczekiwano %d, otrzymano %d", $time, registerName, $signed(expected), $signed(obtained));
			end
		end
	endtask
	
	
	// Zadanie ostrzezenia o nieprawidlowym stanie maszyny stanow
	task assertMachineState;
		input[2:0] obtained;	// Obecna stan maszyny (w zalozeniu reg dane_wy)
		input[2:0] expected;	// Oczekiwany stan maszyny
			
		begin
			if (obtained == expected) begin
				$display("%d ns: Stan maszyny prawidlowy: 0b%b, [%s]", $time, obtained, stateDecode(obtained));
			end else begin
				$display("%d ns: Blad maszyny stanow. Oczekiwano 0b%b (%s), otrzymano 0b%b (%s)", $time, expected, stateDecode(expected), obtained, stateDecode(obtained));
			end
		end
	endtask
	
	
	// Zadanie ostrzezenia o nieprawidlowym rodzaju napoju
	task assertBeverageType;
		input[2:0] obtained;
		input[2:0] expected;
		
		begin
			if (obtained == expected) begin
				$display("%d ns: Wybrany napoj prawidlowy: 0b%b", $time, obtained);
			end else begin
				$display("%d ns: Blad wybranego napoju. Oczekiwano 0b%b, otrzymano 0b%b", $time, expected, obtained);
			end
      end
	endtask
	
	// Zadanie ostrzezenia o nieprawidlowej mocy napoju
	task assertBeverageStrength;
		input[2:0] obtained;
		input[2:0] expected;
		
		begin
			if (obtained == expected) begin
				$display("%d ns: Uzyskano prawidlowa moc napoju: %d", $time, obtained);
			end else begin
				$display("%d ns: Blad uzyskanej mocy napoju. Oczekiwano %d, otrzymano %d", $time, expected, obtained);
			end
      end
	endtask
	
	// Funkcja konwersji stanu maszyny w postaci binarnej na wartosc alfanumeryczna
	function [20*8:1] stateDecode;
		input[2:0] stateCode;
		begin
			if (stateCode == 3'b000) begin
				stateDecode = "STATE_Reset";
			end else if (stateCode == 3'b001) begin
				stateDecode = "STATE_Wybor";
			end else if (stateCode == 3'b011) begin
				stateDecode = "STATE_Moc";
			end else if (stateCode == 3'b010) begin
				stateDecode = "STATE_Platnosc";
			end else if (stateCode == 3'b110) begin
				stateDecode = "STATE_Przygotowanie";
			end else if (stateCode == 3'b100) begin
				stateDecode = "STATE_Reszta";
			end else begin
				stateDecode = "STATE_Unknown";
			end
		end
	endfunction
			
	
endmodule

