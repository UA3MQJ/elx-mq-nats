defmodule MQNATS do
  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      require Logger

      def start_link(initial_state) do
        Logger.info "start_link initial_state=#{inspect initial_state}"
        GenServer.start_link(__MODULE__, initial_state)
      end
      
      def stop(pid) do
        Logger.info "stop pid=#{inspect pid}"
        GenServer.call(pid, :stop)
      end


      ## GenServer callbacks

      def init(%{} = state) do
        Logger.info "init state=#{inspect state}"
        {:ok, state}
      end

      def handle_call(:stop, _from, state) do
        Logger.info "handle_call :stop state=#{inspect state}"
        {:stop, :normal, :ok, state}
      end

    end
  end
end
