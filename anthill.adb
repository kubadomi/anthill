--Adrian Kozień
--Jakub Komnata

with Ada.Text_IO, Ada.Float_Text_IO, Ada.Integer_Text_IO, Ada.Calendar, Ada.Strings, Ada.Strings.Fixed, Ada.Exceptions, Ada.Numerics.Float_Random;
use Ada.Text_IO, Ada.Float_Text_IO, Ada.Integer_Text_IO, Ada.Calendar, Ada.Strings, Ada.Strings.Fixed, Ada.Exceptions;

procedure Anthill is

  Pl : File_Type;
  Nazwa: String := "raport.txt";
  
  InitialAntNumber : Integer := 0;
  MaxAntNumber : Integer := 1000;
  FoodStock : Integer := 0 with Atomic;

  Finish : Boolean := False with Atomic;
  
  type Attributes is (Clear, White, Grey);

  protected Screen  is
    procedure Type_XY(X,Y: Positive; S: String; Attrib : Attributes := Grey);
    procedure Type_float_XY(X, Y: Positive; 
                            Num: Float; 
                            Pre: Natural := 3; 
                            Aft: Natural := 2; 
                            Exp: Natural := 0; 
                            Attrib : Attributes := Grey);
    procedure Clean_Screen;
    procedure Background;
  end Screen;
  
  protected body Screen is
    function Attrib_Fun(Attrib : Attributes) return String is 
      (case Attrib is 
       when White => "m", when Grey => "2m", when Clear => "0m"); 
       
    function Esc_XY(X,Y : Positive) return String is 
      ( (ASCII.ESC & "[" & Trim(Y'Img,Both) & ";" & Trim(X'Img,Both) & "H") );   
       
    procedure Type_XY(X,Y: Positive; S: String; Attrib : Attributes := Grey) is
      Before : String := ASCII.ESC & "[" & Attrib_Fun(Attrib);              
    begin
      Put( Before);
      Put( Esc_XY(X,Y) & S);
      Put( ASCII.ESC & "[0m");
    end Type_XY;  
    
    procedure Type_float_XY(X, Y: Positive; 
                            Num: Float; 
                            Pre: Natural := 3; 
                            Aft: Natural := 2; 
                            Exp: Natural := 0; 
                            Attrib : Attributes := Grey) is
                              
      Previous_String : String := ASCII.ESC & "[" & Attrib_Fun(Attrib);              
    begin
      Put( Previous_String);
      Put( Esc_XY(X, Y) );
      Put( Num, Pre, Aft, Exp);
      Put( ASCII.ESC & "[0m");
    end Type_float_XY; 
    
    procedure Clean_Screen is
    begin
      Put(ASCII.ESC & "[2J");
    end Clean_Screen;   
    
    procedure Background is
    begin
      Screen.Clean_Screen;
      Screen.Type_XY(1,1,"/\/\                  /\/\                    /\/\");
      Screen.Type_XY(3,2,"\_\   _..._           \_\   _..._             \_\   _..._");
      Screen.Type_XY(3,3,"('' )(_..._)          ('' )(_..._)            ('' )(_..._)");
      Screen.Type_XY(4,4,"^^  // \\             ^^  // \\               ^^  // \\");
      Screen.Type_XY(20,5,"Anthill by Komnata/Kozień");
      Screen.Type_XY(3,7,"Number of living =");
      Screen.Type_XY(3,8,"Number of eggs =");
      Screen.Type_XY(3,9,"Number of larvas =");
      Screen.Type_XY(3,10,"Number of pupas =");
      Screen.Type_XY(3,11,"Number of imagos =");
      Screen.Type_XY(3,12,"Number of old ones =");
      Screen.Type_XY(3,13,"Number of dead =");

      Screen.Type_XY(3,15,"Number of food =");

      Screen.Type_XY(3,17,"Number of working =");
      Screen.Type_XY(3,18,"Number of sleeping =");
      Screen.Type_XY(3,19,"Number of eating =");
      Screen.Type_XY(3,20,"Number of waiting =");
      Screen.Type_XY(3,21,"Number of reproducting =");

      Screen.Type_XY(3,23,"Work Heaviness:");
      Screen.Type_XY(3,24,"Time (sec):");
      Screen.Type_XY(3,25,"Season of the year");
      Screen.Type_XY(3,26,"Finish - q, Steal 50 food - k, Harder work - c, Lighter work - v (Work Heaviness from 0-100)");
      
      
    end Background; 
        
  end Screen;
  
  task Process is
    entry Steal;
    entry DoWork;
    entry DoLightWork;
    entry NewAnt;
    entry Start;
  end Process;

  task body Process is 

    SeasonNum : Integer := 0;
    Tick : Integer := 0;
    Season : String := "Season";
    FoodCollected : Integer := 1;
    FoodNeeded : Integer := 10;
    EnergyNeeded : Integer := 10;


    Next : Ada.Calendar.Time;
    Cycle : constant Duration := 1.0;
    MoveOfCycle : constant Duration := 0.5;
    
    NumberOfAnts : Integer := 0 with Atomic;
    NumberOfEggs : Integer := 0 with Atomic;
    NumberOfLarvas : Integer := 0 with Atomic;
    NumberOfPupas : Integer := 0 with Atomic;
    NumberOfImagos : Integer := 0 with Atomic;
    NumberOfOldOnes : Integer := 0 with Atomic;
    NumberOfDead : Integer := 0 with Atomic;

    NumberOfSleepingAnts : Integer := 0 with Atomic;
    NumberOfEatingAnts : Integer := 0 with Atomic;
    NumberOfWaitingAnts : Integer := 0 with Atomic;
    NumberOfWorkingAnts : Integer := 0 with Atomic;
    NumberOfReproducingAnts : Integer := 0 with Atomic;

    WorkHeaviness : Integer := 20 with Atomic;

    procedure StealFood is
    begin
      FoodStock := FoodStock - 50;
      if FoodStock <= 0
      then FoodStock := 0;
      end if;
    end StealFood;

    procedure HardWork is
    begin
      WorkHeaviness := WorkHeaviness + 10;
      if WorkHeaviness >= 100
      then WorkHeaviness := 100;
      end if;
    end HardWork;

    procedure LightWork is
    begin
      WorkHeaviness := WorkHeaviness - 10;
      if WorkHeaviness <= 0
      then WorkHeaviness := 0;
      end if;
    end LightWork;

    type AntState is (Egg, Larva, Pupa, Imago, OldOne);
    type AntActivity is (Work, Food, Sleep, Wait, Reproduction);

    protected type Semaphore is
        entry Wait;
        procedure Sygnalize;
    private
        Sem : Boolean := True;
    end Semaphore;

    protected body Semaphore is
        entry Wait when Sem is
        begin
            Sem := False;
        end Wait;

        procedure Sygnalize is
        begin
            Sem := True;
        end Sygnalize;
    end Semaphore;

    FoodSemaphore : Semaphore;

    SleepSemaphore : Semaphore;

    SemaphoreOfWorkingOnes : Semaphore;

    SemaphoreOfSleepingOnes : Semaphore;

    SemaphoreOfEatingOnes : Semaphore;

    SemaphoreOfWaitingOnes : Semaphore;

    SemaphoreOfReproducingOnes : Semaphore;

    AntSemaphore : Semaphore;

    EggSemaphore : Semaphore;

    LarvaSemaphore : Semaphore;

    PupaSemaphore : Semaphore;

    ImagoSemaphore : Semaphore;
    
    OldOnesSemaphore : Semaphore;

    DeadOnesSemaphore : Semaphore;

    task type Ant is
      entry Start;	
    end Ant;

    task body Ant is
      use Ada.Numerics.Float_Random;

      Gen : Generator;

      Energy : Integer := 100;
      LevelOfStomachFullness : Float := 100.0;
      Activity : AntActivity := Wait;

      ChangedState : Boolean := false;
      WaitingForSleep :Boolean := false;
      WaitingForFood : Boolean := false;

      Age : Integer := 0;
      State : AntState := Egg;
      NextM : Ada.Calendar.Time;
      CycleM : constant Duration := 3.0; -- sec
      MoveOfCycleM : Duration := 0.4;

      procedure AbandonPreviousActivity is begin
        case Activity is
          when Work =>
            SemaphoreOfWorkingOnes.Wait;
            NumberOfWorkingAnts := NumberOfWorkingAnts - 1;
            SemaphoreOfWorkingOnes.Sygnalize;
          when Food => 
            SemaphoreOfEatingOnes.Wait;
            NumberOfEatingAnts := NumberOfEatingAnts - 1;
            SemaphoreOfEatingOnes.Sygnalize;
          when Sleep =>
            SemaphoreOfSleepingOnes.Wait;
            NumberOfSleepingAnts := NumberOfSleepingAnts - 1;
            SemaphoreOfSleepingOnes.Sygnalize;
          when Wait => 
            SemaphoreOfWaitingOnes.Wait;
            NumberOfWaitingAnts := NumberOfWaitingAnts - 1;
            SemaphoreOfWaitingOnes.Sygnalize;
          when Reproduction => 
            SemaphoreOfReproducingOnes.Wait;
            NumberOfReproducingAnts := NumberOfReproducingAnts - 1;
            SemaphoreOfReproducingOnes.Sygnalize;
        end case;
      end AbandonPreviousActivity;

    begin
      Reset(Gen);

      MoveOfCycleM := MoveOfCycleM + Duration(Random(Gen)); -- rozrzucenie przesuniecia

      accept Start;
      AntSemaphore.Wait;
      NumberOfAnts := NumberOfAnts + 1;
      AntSemaphore.Sygnalize;
      EggSemaphore.Wait;
      NumberOfEggs := NumberOfEggs + 1;
      EggSemaphore.Sygnalize;
      SemaphoreOfWaitingOnes.Wait;
      NumberOfWaitingAnts := NumberOfWaitingAnts + 1;
      SemaphoreOfWaitingOnes.Sygnalize;
      NextM := Clock + MoveOfCycleM;
      loop
        delay until NextM;
        Age := Age + 1;

        case Age is
         when 2 =>
          EggSemaphore.Wait;
          NumberOfEggs := NumberOfEggs - 1;
          EggSemaphore.Sygnalize;
          LarvaSemaphore.Wait;
          NumberOfLarvas := NumberOfLarvas + 1;
          LarvaSemaphore.Sygnalize;
          State := Larva;  
         when 4 => 
          LarvaSemaphore.Wait;
          NumberOfLarvas := NumberOfLarvas - 1;
          LarvaSemaphore.Sygnalize;
          PupaSemaphore.Wait;
          NumberOfPupas := NumberOfPupas + 1;
          PupaSemaphore.Sygnalize;
          State := Pupa;
         when 8 => 
          PupaSemaphore.Wait;
          NumberOfPupas := NumberOfPupas - 1;
          PupaSemaphore.Sygnalize;
          ImagoSemaphore.Wait;
          NumberOfImagos := NumberOfImagos + 1;
          ImagoSemaphore.Sygnalize;
          State := Imago;
         when 16 => 
          ImagoSemaphore.Wait;
          NumberOfImagos := NumberOfImagos - 1;
          ImagoSemaphore.Sygnalize;
          OldOnesSemaphore.Wait;
          NumberOfOldOnes := NumberOfOldOnes + 1;
          OldOnesSemaphore.Sygnalize;
          State := OldOne;
         when 32 =>
          AntSemaphore.Wait;
          NumberOfAnts := NumberOfAnts - 1;
          AntSemaphore.Sygnalize;
          OldOnesSemaphore.Wait;
          NumberOfOldOnes := NumberOfOldOnes - 1;
          OldOnesSemaphore.Sygnalize;
          DeadOnesSemaphore.Wait;
          NumberOfDead := NumberOfDead + 1;
          DeadOnesSemaphore.Sygnalize;
          
          AbandonPreviousActivity;

          exit;
         when others => null; 
        end case;


        if State = Imago or else State = OldOne
        then

          if LevelOfStomachFullness <= 0.0 or else Energy <= 0
          then
            AntSemaphore.Wait;
            NumberOfAnts := NumberOfAnts - 1;
            AntSemaphore.Sygnalize;
            DeadOnesSemaphore.Wait;
            NumberOfDead := NumberOfDead + 1;
            DeadOnesSemaphore.Sygnalize;
            if Age >= 16
            then 
              OldOnesSemaphore.Wait;
              NumberOfOldOnes := NumberOfOldOnes - 1;
              OldOnesSemaphore.Sygnalize;
            else
              ImagoSemaphore.Wait;
              NumberOfImagos := NumberOfImagos - 1;
              ImagoSemaphore.Sygnalize;
            end if;
            AbandonPreviousActivity;
            exit;
          end if;

          if Energy < 21
          then
            SleepSemaphore.Wait;
              if Float(NumberOfSleepingAnts) / Float(NumberOfAnts) < 0.2
              then
                AbandonPreviousActivity;
                Activity := Sleep;
                NumberOfSleepingAnts := NumberOfSleepingAnts + 1;
                Energy := Energy + 80;
                LevelOfStomachFullness := LevelOfStomachFullness - 10.0;
                WaitingForSleep := false;
                ChangedState := true;
              else
                WaitingForSleep := true;
                ChangedState := false;
              end if;
            SleepSemaphore.Sygnalize;
          end if;

          if LevelOfStomachFullness < 21.0 and then ChangedState = false
          then
            FoodSemaphore.Wait;
              if FoodStock > 5
              then
                AbandonPreviousActivity;
                Activity := Food;
                NumberOfEatingAnts := NumberOfEatingAnts + 1;
                LevelOfStomachFullness := LevelOfStomachFullness + 50.0;
                Energy := Energy - EnergyNeeded;
                FoodStock := FoodStock - FoodNeeded;
                WaitingForFood := false;
                ChangedState := true;
              else
                WaitingForFood := true;
                ChangedState := false;
              end if;
            FoodSemaphore.Sygnalize;
          end if;
          
          if ChangedState = false
          then
            if WaitingForFood = true or else WaitingForSleep = true 
            then
              AbandonPreviousActivity;
              Activity := Wait;
              SemaphoreOfWaitingOnes.Wait;
              NumberOfWaitingAnts := NumberOfWaitingAnts + 1;
              SemaphoreOfWaitingOnes.Sygnalize;
              Energy := Energy - 3;
              LevelOfStomachFullness := LevelOfStomachFullness - 5.0;
            elsif Random(Gen) < 0.15 then
              AbandonPreviousActivity;
              Activity := Reproduction;
              SemaphoreOfReproducingOnes.Wait;
              NumberOfReproducingAnts := NumberOfReproducingAnts + 1;
              SemaphoreOfReproducingOnes.Sygnalize;
              Energy := Energy - 5;
              LevelOfStomachFullness := LevelOfStomachFullness - 10.0;
              Process.NewAnt;
            else
              AbandonPreviousActivity;
              Activity := Work;
              SemaphoreOfWorkingOnes.Wait;
              NumberOfWorkingAnts := NumberOfWorkingAnts + 1;
              SemaphoreOfWorkingOnes.Sygnalize;
              Energy := Energy - WorkHeaviness;
              LevelOfStomachFullness := LevelOfStomachFullness - 30.0;
              FoodStock := FoodStock + FoodCollected;
            end if;
          end if;

        else
          Activity := Wait;
        end if;

        WaitingForFood := false;
        WaitingForSleep := false;
        ChangedState := false;

        NextM := NextM + CycleM;
      end loop;
    end Ant;    

    subtype RangeM is Integer range 1..MaxAntNumber; 
    Ants : array(RangeM) of Ant;

    Counter : Integer := 1 with Atomic;

  begin
    accept Start;

    Next := Clock + MoveOfCycle;
    loop
      delay until Next;

      select
        accept Steal do
          StealFood;
        end Steal;
      or
        accept DoWork do
          HardWork;
        end DoWork;
      or
        accept DoLightWork do
          LightWork;
        end DoLightWork;
      or
        accept NewAnt do
          if Counter <= MaxAntNumber
          then
            Ants(Counter).Start;
            Counter := Counter + 1;
          end if;
        end NewAnt;
      else
        null;
      end select;

      if Counter <= InitialAntNumber
      then
        Ants(Counter).Start;
        Counter := Counter + 1;
      end if;

      Tick := Tick + 1;
      if SeasonNum >= 0 and SeasonNum < 4
      then
        Season := "Spring";
        FoodNeeded := 10;
        FoodCollected := 2;
        EnergyNeeded := 10;
      elsif SeasonNum >= 4 and SeasonNum < 8
      then  
        Season := "Summer";
        FoodCollected := 4;
        FoodNeeded := 15;
      elsif SeasonNum >= 8 and SeasonNum < 12
      then
        Season := "Autumn";
        FoodCollected := 3;
        FoodNeeded := 15;
        EnergyNeeded := 15;
      elsif SeasonNum >= 12 and SeasonNum < 16
      then 
        Season := "Winter";
        FoodCollected := 2;
        FoodNeeded := 1;
        EnergyNeeded := 10;
      end if;
      SeasonNum := SeasonNum + 1;
      if SeasonNum >= 16
      then
        SeasonNum := 0;
      end if;
      if FoodStock <= 0
      then FoodStock := 0;
      end if;

--Zapis do pliku raport.txt

open(Pl,Append_File,Nazwa);
  
	Put_Line(Pl,Tick'Img & ", " & Season & ", " & NumberOfAnts'Img & ", " & NumberOfEggs'Img & ", " & NumberOfLarvas'Img & ", " & NumberOfPupas'Img & ", " &  NumberOfImagos'Img & ", " & NumberOfOldOnes'Img & ", " & NumberOfDead'Img & ", " & FoodStock'Img & ", " & NumberOfWorkingAnts'Img & ", " &  NumberOfSleepingAnts'Img & ", " &  NumberOfEatingAnts'Img & ", " & NumberOfWaitingAnts'Img & ", " &  NumberOfReproducingAnts'Img & ", " &  WorkHeaviness'Img & " " );
  	  
  Close(Pl);

      Screen.Type_XY(28 ,7, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 7, NumberOfAnts'Img, Attrib=>White);
      Screen.Type_XY(28 ,8, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 8, NumberOfEggs'Img, Attrib=>White);
      Screen.Type_XY(28 ,9, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 9, NumberOfLarvas'Img, Attrib=>White);
      Screen.Type_XY(28 ,10, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 10, NumberOfPupas'Img, Attrib=>White);
      Screen.Type_XY(28 ,11, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 11, NumberOfImagos'Img, Attrib=>White);
      Screen.Type_XY(28 ,12, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 12, NumberOfOldOnes'Img, Attrib=>White);
      Screen.Type_XY(28 ,13, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 13, NumberOfDead'Img, Attrib=>White);


      Screen.Type_XY(28 ,15, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 15, FoodStock'Img, Attrib=>White);
      --Screen.Type_XY(31 ,15, 20*' ', Attrib=>Clear);

      Screen.Type_XY(28 ,17, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 17, NumberOfWorkingAnts'Img, Attrib=>White);
      Screen.Type_XY(28 ,18, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 18, NumberOfSleepingAnts'Img, Attrib=>White);
      Screen.Type_XY(28 ,19, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 19, NumberOfEatingAnts'Img, Attrib=>White);
      Screen.Type_XY(28 ,20, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 20, NumberOfWaitingAnts'Img, Attrib=>White);
      Screen.Type_XY(28 ,21, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 21, NumberOfReproducingAnts'Img, Attrib=>White);


      Screen.Type_XY(28 ,23, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 23, WorkHeaviness'Img, Attrib=>White);

      Screen.Type_XY(28 ,24, 20*' ', Attrib=>Clear);
      Screen.Type_XY(28, 24, Tick'Img, Attrib=>White);

      Screen.Type_XY(29 ,25, 20*' ', Attrib=>Clear);
      Screen.Type_XY(29, 25, Season, Attrib=>White);
      Screen.Type_XY(29,28,"Dane sa zapisane do pliku raport.txt");
      --Put_Line( "Dane sa zapisywane do pliku raport.txt");
      exit when Finish;
      Next := Next + Cycle;
    end loop; 
    exception
      when E:others =>
        Put_Line("Error: Task Process");
        Put_Line(Exception_Name (E) & ": " & Exception_Message (E)); 
  end Process;

  Ch : Character;
  
begin
  -- inicjowanie
Create(Pl, Out_File, Nazwa); -- Tworzenie pliku raport.txt
Put_Line(Pl,"time,season,living,eggs,larvas,pupas,imagos,old_ones,dead,food,working,sleeping,eating,waiting,reproducting,heavines");
Close(Pl);
    Put_Line("");
    Put_Line("Set initial number of ants: ");
    Get(InitialAntNumber);
    Put_Line("Set maximum number of ants: ");
    Get(MaxAntNumber);
    Put_Line("Set initial number of food: ");
    Get(FoodStock);
	
    Process.Start;

  Screen.Background; 
  loop
    Get_Immediate(Ch);
    exit when Ch in 'q'|'Q';
    if Ch in 'K'|'k' 
    then 
      Process.Steal;
    elsif Ch in 'C' | 'c'
    then 
      Process.DoWork;
    elsif Ch in 'V' | 'v'
    then 
      Process.DoLightWork;
    end if;
  end loop; 
  Finish := True;
end Anthill;    
