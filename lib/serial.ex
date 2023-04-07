defmodule NauticNet.TrackerUplink.Serial do
  use GenServer
  require Logger

  alias Circuits.UART.Framing.Line

  def start_link(state), do: GenServer.start_link(__MODULE__, state, name: __MODULE__)

  @impl true
  def init(_) do
    uart_pid = setup_UART()

    {:ok, uart_pid}
  end

  @impl true
  def handle_info({:circuits_uart, _serial_port_id, {:error, reason}}, state) do
    Logger.info("error: #{inspect(reason)}")

    {:noreply, state}
  end

  def handle_info({:circuits_uart, _serial_port_id, data}, state) do
    Logger.info("UART: #{inspect(data)}")

    {:noreply, state}
  end

  defp setup_UART do
    {:ok, pid} = Circuits.UART.start_link()

    # Replace port for Adafruit Feather Microcontroller
    # :ok = Circuits.UART.open(pid, "ttyACM0", speed: 9600, active: true, framing: {Line, separator: "\r\n"})

    pid
  end
end
