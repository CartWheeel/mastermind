-module(mastermind).
-export([play_game/0]).

% Utility functions

% Function to generate a 4-character random code from the list of numbers
generate_code() ->
    Numbers = [1, 2, 3, 4, 5, 6],
    [lists:nth(rand:uniform(length(Numbers)), Numbers) || _ <- lists:seq(1, 4)].

% Helper function to check if the guess is valid
is_valid_guess(Guess) ->
    %% Check that Guess has exactly 4 characters and each is between '1' and '6'
    length(Guess) =:= 4 andalso
    lists:all(fun(Char) -> lists:member(Char, "123456") end, Guess).

% Function to get user input as a guess, ensuring it’s exactly 4 digits from the allowed numbers
get_guess() ->
    io:format("Enter Guess: "),
    Input = io:get_line(""),
    TrimmedGuess = string:trim(Input), % Trim newline

    case is_valid_guess(TrimmedGuess) of
        true -> [element(1, string:to_integer([Char])) || Char <- TrimmedGuess];
        false ->
            io:format("Invalid input. Please enter exactly 4 digits from 1 to 6.~n"),
            get_guess()
    end.

% Game Board Functions

% Function to display the initial blank practice board
blank_board(_Code) ->
    %% Clear the terminal
    io:format("~c[H~c[2J", [27, 27]),
    % io:format(" Code:  ~s~n", [lists:flatten(io_lib:format("~p", [Code]))]), % Uncomment and remove underscore to see code at beginning.
    io:format(" ________________ ~n"),
    io:format("|___MASTERMIND___|~n"),
    lists:foreach(
        fun(_) -> io:format("|                |~n| - -            |~n| - -    - - - - |~n") end,
        lists:seq(1, 8)
    ),
    io:format("|________________|~n|__1_2_3__4_5_6__|~n~n").

% Function to update the board after each guess
update_board(TotalGuesses) ->
    %% Clear the terminal
    io:format("~c[H~c[2J", [27, 27]),
    io:format(" ________________ ~n"),
    io:format("|___MASTERMIND___|~n"),
    lists:foreach(
        fun({Guess, HintA, HintB}) ->
            io:format("|                |~n"),
            io:format("| ~s            |~n", [string:join(HintA, " ")]),
            io:format("| ~s    ~s |~n", [string:join(HintB, " "), string:join([integer_to_list(D) || D <- Guess], " ")])
        end,
        lists:reverse(TotalGuesses)  % Reverse for display order
    ),
    %% Fill remaining slots with blanks if less than 8 guesses
    RemainingGuesses = 8 - length(TotalGuesses),
    lists:foreach(
        fun(_) -> io:format("|                |~n| - -            |~n| - -    - - - - |~n") end,
        lists:seq(1, RemainingGuesses)
    ),
    io:format("|________________|~n|__1_2_3__4_5_6__|~n~n").

% Main Game Functions

% Function to check if the Guess and the Code are the same
check_guess(Code, Guess) ->
    %% Step 1: Mark 'O' for correct position matches
    {Matches, UnmatchedCode, UnmatchedGuess} = lists:foldl(
        fun({CodeDigit, GuessDigit}, {AccMatches, AccCode, AccGuess}) ->
            if
                CodeDigit == GuessDigit ->
                    {["O" | AccMatches], AccCode, AccGuess};
                true ->
                    {AccMatches, [CodeDigit | AccCode], [GuessDigit | AccGuess]}
            end
        end,
        {[], [], []},
        lists:zip(Code, Guess)
    ),
    %% Step 2: Mark 'X' for correct digits in wrong positions, without duplicating matches
    {X_Matches, _RemainingCode} = lists:foldl(
        fun(GuessDigit, {AccMatches, AccCode}) ->
            case lists:member(GuessDigit, AccCode) of
                true ->
                    {["X" | AccMatches], lists:delete(GuessDigit, AccCode)};
                false ->
                    {AccMatches, AccCode}
            end
        end,
        {[], UnmatchedCode},
        UnmatchedGuess
    ),
    %% Fill remaining slots with '-' only up to the original length of the guess
    Hint = lists:reverse(lists:append(Matches, X_Matches)),
    lists:append(Hint, lists:duplicate(length(Code) - length(Hint), "-")).

% Main game loop
play_game() ->
    rand:seed(exsplus, erlang:timestamp()), % Initializes random seed
    Code = generate_code(),
    blank_board(Code),
    play_game_loop(Code, [], 1).

play_game_loop(Code, Guesses, Turn) when Turn =< 8 ->
    Guess = get_guess(),
    Hint = check_guess(Code, Guess),
    %% Split the hint into two halves
    {HintA, HintB} = lists:split(2, Hint),
    TotalGuesses = [{Guess, HintA, HintB} | Guesses],
    update_board(TotalGuesses),
    %% Check if the guess is correct or if the game should continue
    case Hint of
        ["O", "O", "O", "O"] ->
            io:format("Congratulations! You guessed the code!~n"),
            play_again();
        _ ->
            play_game_loop(Code, TotalGuesses, Turn + 1)
    end;

play_game_loop(Code, _, _) ->
    io:format("Game over! The correct code was: ~s~n", [lists:flatten(io_lib:format("~p", [Code]))]),
    play_again().

% Play again prompt
play_again() ->
    io:format("Would you like to play again? (y/n): "),
    get_play_again_answer().

% Helper function for handling play again input
get_play_again_answer() ->
    Answer = string:trim(io:get_line("")),
    case Answer of
        "y" -> play_game();
        "n" -> io:format("Thank you for playing!~n"), ok;
        _ -> io:format("Invalid input. Please type 'y' or 'n'.~n"), get_play_again_answer()
    end.
