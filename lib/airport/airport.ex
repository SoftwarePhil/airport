defmodule Customer do
    defstruct [:type, :id]
end

defmodule Terminal do
    defstruct [:type, :id, :customer, :counter, :every]
end

#Airport.Airport.run
defmodule Airport.Airport do
    defstruct [:fc_line, :c_line, :fc_gen, :c_gen, :fc_terminals, :c_terminals]

    @run_time 100
    @fc_gen_time 1
    @c_gen_time 5
    @terminal_time 6
    @fc_terminal_number 2
    @c_terminal_number 3

    import Terminal
    import Customer
    
    def run do
        state = init(@fc_gen_time, @c_gen_time)
        step(state, @run_time)
    end

    def init(fc_gen_time, c_gen_time) do
        fc_terminals =
            Enum.map(0..@fc_terminal_number, 
                fn(i) ->  %Terminal{type: :first, id: i, customer: nil, every: @terminal_time, counter: 0} 
            end)

        c_terminals =
            Enum.map(0..@c_terminal_number, 
                fn(i) -> %Terminal{type: :couch, id: i, customer: nil, every: @terminal_time, counter: 0} 
            end)
        
        %Airport.Airport{
                    fc_line: [], c_line: [], 
                    fc_gen: time_passed(fc_gen_time), 
                    c_gen: time_passed(c_gen_time), 
                    fc_terminals: fc_terminals,
                    c_terminals: c_terminals
                   }
    end

    def step(state, run_time) when run_time > 0 do
        IO.puts("\n___Start____")
        fc_line = line(run_time, state.fc_gen, state.fc_line, :first)
        c_line = line(run_time, state.fc_gen, state.fc_line, :coach)

        {fc_terminals, fc_line}  = terminal(run_time, state.fc_terminals, fc_line)
        {c_terminals, c_line, fc_terminals, fc_line}  = terminal_c(run_time, state.c_terminals, c_line, fc_terminals, fc_line)
       
        new_state = %__MODULE__{state | fc_line: fc_line, fc_terminals: fc_terminals, c_line: c_line, c_terminals: c_terminals}
        IO.inspect("--------end--------")
        step(new_state, run_time - 1)
    end

    def step(state, _run_time) do
        IO.puts("\n\n--------- simulation finished -----\n\n")
        IO.inspect(state)
    end

    def line(run_time, gen, line, type) do
        case {gen.(run_time), type} do
                {true, :first}  -> 
                    customer = %Customer{type: type, id: run_time + 1000}
                    IO.inspect({customer, "has arrived at step", run_time})
                    [customer | line]
                {true, :coach}  -> 
                    customer = %Customer{type: type, id: run_time}
                    IO.inspect({customer, "has arrived at step", run_time})
                    [customer | line]
                {false, _} -> line
        end
    end

    def terminal(run_time, terminals, fc_list), do: _terminal(run_time, terminals, fc_list, [])
    defp _terminal(run_time, [terminal | rest], fc_list, done_terminals) do
            tcount = terminal.counter
            case tcount < 1 do
                true -> 
                    cond do
                        length(fc_list) > 0 ->
                            tcount = terminal.every
                            customer = List.last(fc_list)
                            IO.inspect({customer, "has gotten terminal to", terminal.id, " at ", run_time})
                            _terminal(run_time, rest, List.delete_at(fc_list, length(fc_list) - 1), done_terminals ++ [%Terminal{terminal |customer: customer, counter: tcount}])
                        true -> _terminal(run_time, rest, fc_list, done_terminals ++ [terminal])
                    end
                _  -> _terminal(run_time, rest, fc_list, done_terminals ++ [%{terminal | counter: tcount - 1}])
            end
    end
    defp _terminal(_run_time, [], fc_list, terminals) do
        {terminals, fc_list}
    end

   def terminal_c(run_time, terminals_c, c_list, terminals_fc, fc_list) do
        {terminals_c, c_list} = terminal(run_time, terminals_c, c_list)
        cond do 
            length(fc_list) == 0 -> 
                {terminals_fc, c_list} = terminal(run_time, terminals_fc, c_list)
                {terminals_c, c_list, terminals_fc, fc_list}
            true -> {terminals_c, c_list, terminals_fc, fc_list}
        end
   end

    #if no first class customers are waiting, coach customers can use first class terminals, so try that first!
    def time_passed(every) do
        fn (current_step) -> 
            case rem(current_step, every) do
                0 -> true
                _ -> false
            end
        end
    end
end
