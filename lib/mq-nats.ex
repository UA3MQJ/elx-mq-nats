defmodule MQNATS do

  require Logger
  Logger.info ">>> MQNATS"

  defmacro __using__(_) do
    quote location: :keep do
      @service_name NatsService
      use GenServer
      require Logger

      def start_link(),            do: GenServer.start_link(__MODULE__, [nats_config()])
      def stop(pid),               do: GenServer.call(pid, :stop)
      def connect(pid),            do: GenServer.call(pid, :connect)
      def disconnect(pid),         do: GenServer.call(pid, :disconnect)
      def subscribe(pid, subj),    do: GenServer.call(pid, {:subscribe, subj})
      def unsubscribe(pid, subj),  do: GenServer.call(pid, {:unsubscribe, subj})
      def publish(pid, subj, msg), do: GenServer.call(pid, {:publish, subj, msg})

      # GenServer callbacks
      def init([nats_config]) do
        state = %{
          nats_config: nats_config,
          nats_pid: nil,
          nats_status: :disconnected,
          subj2ref: %{}
        }

        {:ok, state}
      end

      def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state}
      end

      def handle_call(:connect, _from, state) do
        nats_config = state.nats_config
        case Nats.Client.start_link(@service_name, nats_config) do
          {:ok, nats_pid} ->
            on_connect(%{nats_pid: nats_pid})
            {:reply, {:ok, %{nats_pid: nats_pid}}, %{state| nats_pid: nats_pid, nats_status: :connected}}
          error ->
            {:reply, :error, state}
        end
      end

      def handle_call(:disconnect, _from, state) do
        Nats.Client.stop(@service_name)
        on_disconnect()
        {:reply, :ok, %{state| nats_pid: nil, nats_status: :disconnected, subj2ref: %{}}}
      end

      def handle_call({:subscribe, subj}, _from, state) do
        {:ok, ref} = Nats.Client.sub(@service_name, self(), subj)
        new_subj2ref = Map.merge(state.subj2ref, %{subj => ref})
        on_subscribe(%{subj: subj})
        {:reply, {:ok, ref}, %{state| subj2ref: new_subj2ref}}
      end

      def handle_call({:unsubscribe, subj}, _from, state) do
        case state.subj2ref[subj] do
          # subscription not exist
          nil ->
            {:reply, :error, state}
          ref ->
            Logger.debug "unsub ref=#{inspect ref}"
            case Nats.Client.unsub(@service_name, ref, subj) do
              :ok ->
                on_unsubscribe(%{subj: subj})
                new_subj2ref = Map.delete(state.subj2ref, subj)
                {:reply, {:ok, %{subj: subj}}, %{state| subj2ref: new_subj2ref}}
              _error ->
                {:reply, :error, state}
            end
        end
      end

      def handle_call({:publish, subj, msg}, _from, state) do
        :ok = Nats.Client.pub(@service_name, subj, msg)
        on_publish(%{subj: subj, msg: msg})
        {:reply, :ok, state}
      end

      def handle_info({:msg, _, subject, _reply, message} = msg, state) do
        Logger.debug ">>>> info :msg msg=#{inspect msg}"
        on_subscribed_publish(%{subject: subject, message: message})
        {:noreply, state}
      end

      # Overrideable callbacks
      def on_connect(_info), do: true
      def on_disconnect(), do: true
      def on_subscribe(_info), do: true
      def on_unsubscribe(_info), do: true
      def on_subscribed_publish(_info), do: true
      def on_publish(_info), do: true

      defoverridable [
                      on_connect: 1,
                      on_disconnect: 0,
                      on_subscribe: 1,
                      on_unsubscribe: 1,
                      on_subscribed_publish: 1,
                      on_publish: 1
                     ]

      # local functions
      # read NATS parameters from config/config.exs
      defp nats_config() do
        config = Application.get_env(:mqnats, :mqnats, %{})

        unless is_bitstring(config.host) do
          raise({:bad_host, config.host})
        end

        unless is_integer(config.port) do
          raise({:bad_port, config.port})
        end
        
        unless is_integer(config.timeout) do
          raise({:bad_timeout, config.timeout})
        end

        config
      end
    end
  end
end
