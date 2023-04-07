defmodule NauticNet.TrackerUplink.LoraRadio do
  use GenServer

  require Logger

  alias NauticNet.Protobuf.LoRaPacket
  alias NauticNet.Protobuf.RoverData

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    #
    # Couple notes:
    #   - /dev/spidev0.1 is the SPI device on the Raspberry Pi 2 B+
    #   - The :encoding option requires the fork of the :lora dependency at
    #     https://github.com/schrockwell/Elixir-LoRa/tree/add-encoding
    #
    {:ok, lora_pid} = LoRa.start_link(spi: "spidev0.1", encoding: :binary)

    LoRa.begin(lora_pid, 915.0e6)
    LoRa.set_spreading_factor(lora_pid, 9)
    LoRa.set_signal_bandwidth(lora_pid, 500.0e3)

    Logger.info("LoRa radio initialized")

    {:ok, %{lora_pid: lora_pid}}
  end

  @impl true
  def handle_info({:lora, message}, state) do
    Logger.info("Got message: #{inspect(message)}")
    Logger.info("Got packet: #{Base.encode64(message.packet)}")

    # Not sure what these leading bytes are about
    <<0xFF, 0xFF, 0x00, 0x00, bytes::binary>> = message.packet

    packet = LoRaPacket.decode(bytes)
    hardware_id = Base.encode16(<<packet.hardwareID::32>>)

    case packet.payload do
      {:roverData, %RoverData{} = rover_data} ->
        # TODO: SOMETHING
        # lat = rover_data.latitude
        # lon = rover_data.longitude
        heel = rover_data.heel / 10.0 - 90.0

      _ ->
        :ok
    end

    Logger.info("Decoded packet: #{inspect(packet)}")

    {:noreply, state}
  rescue
    error ->
      Logger.warn("Error decoding packet: #{inspect(error)}")
      {:noreply, state}
  end
end
