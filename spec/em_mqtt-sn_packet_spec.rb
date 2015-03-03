$:.unshift(File.dirname(__FILE__))

require 'spec_helper'

describe EventMachine::MQTTSN::Packet do

  describe "when creating a new packet" do
    it "should allow you to set the packet dup flag as a hash parameter" do
      packet = EventMachine::MQTTSN::Packet.new( :duplicate => true )
      expect(packet.duplicate).to be_truthy
    end

    it "should allow you to set the packet QOS level as a hash parameter" do
      packet = EventMachine::MQTTSN::Packet.new( :qos => 2 )
      expect(packet.qos).to eq(2)
    end

    it "should allow you to set the packet retain flag as a hash parameter" do
      packet = EventMachine::MQTTSN::Packet.new( :retain => true )
      expect(packet.retain).to be_truthy
    end
  end

  describe "getting the type id on a un-subclassed packet" do
    it "should throw an exception" do
      expect {
        EventMachine::MQTTSN::Packet.new.type_id
      }.to raise_error(
        RuntimeError,
        "Invalid packet type: EventMachine::MQTTSN::Packet"
      )
    end
  end

  describe "Parsing a packet that does not match the packet length" do
    it "should throw an exception" do
      expect {
        packet = EventMachine::MQTTSN::Packet.parse("\x02\x1834567")
      }.to raise_error(
        EventMachine::MQTTSN::ProtocolException,
        "Length of packet is not the same as the length header"
      )
    end
  end

end


describe EventMachine::MQTTSN::Packet::Connect do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Connect.new
    expect(packet.type_id).to eq(0x04)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a packet with no flags" do
      packet = EventMachine::MQTTSN::Packet::Connect.new(
        :client_id => 'mqtt-sn-client-pub'
      )
      expect(packet.to_s).to eq("\x18\x04\x04\x01\x00\x0fmqtt-sn-client-pub")
    end

    it "should output the correct bytes for a packet with clean session turned off" do
      packet = EventMachine::MQTTSN::Packet::Connect.new(
        :client_id => 'myclient',
        :clean_session => false
      )
      expect(packet.to_s).to eq("\016\004\000\001\000\017myclient")
    end

    it "should throw an exception when there is no client identifier" do
      expect {
        EventMachine::MQTTSN::Packet::Connect.new.to_s
      }.to raise_error(
        'Invalid client identifier when serialising packet'
      )
    end

    it "should output the correct bytes for a packet with a will request" do
      packet = EventMachine::MQTTSN::Packet::Connect.new(
        :client_id => 'myclient',
        :request_will => true,
        :clean_session => true
      )
      expect(packet.to_s).to eq("\016\004\014\001\000\017myclient")
    end

    it "should output the correct bytes for with a custom keep alive" do
      packet = EventMachine::MQTTSN::Packet::Connect.new(
        :client_id => 'myclient',
        :request_will => true,
        :clean_session => true,
        :keep_alive => 30
      )
      expect(packet.to_s).to eq("\016\004\014\001\000\036myclient")
    end
  end

  describe "when parsing a simple Connect packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse(
        "\x18\x04\x04\x01\x00\x00mqtt-sn-client-pub"
      )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Connect)
    end

    it "should not have the request will flag set" do
      expect(@packet.request_will).to be_falsy
    end

    it "shoul have the clean session flag set" do
      expect(@packet.clean_session).to be_truthy
    end

    it "should set the Keep Alive timer of the packet correctly" do
      expect(@packet.keep_alive).to eq(0)
    end

    it "should set the Client Identifier of the packet correctly" do
      expect(@packet.client_id).to eq('mqtt-sn-client-pub')
    end
  end

  describe "when parsing a Connect packet with the clean session flag set" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse(
        "\016\004\004\001\000\017myclient"
      )
    end

    it "should set the clean session flag" do
      expect(@packet.clean_session).to be_truthy
    end
  end

  describe "when parsing a Connect packet with the will request flag set" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse(
        "\016\004\014\001\000\017myclient"
      )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Connect)
    end
    it "should set the Client Identifier of the packet correctly" do
      expect(@packet.client_id).to eq('myclient')
    end

    it "should set the clean session flag should be set" do
      expect(@packet.clean_session).to be_truthy
    end

    it "should set the Will retain flag should be false" do
      expect(@packet.request_will).to be_truthy
    end
  end

  context "that has an invalid type identifier" do
    it "should throw an exception" do
      expect {
        EventMachine::MQTTSN::Packet.parse( "\x02\xFF" )
      }.to raise_error(
        EventMachine::MQTTSN::ProtocolException,
        "Invalid packet type identifier: 255"
      )
    end
  end

  describe "when parsing a Connect packet an unsupport protocol ID" do
    it "should throw an exception" do
      expect {
        packet = EventMachine::MQTTSN::Packet.parse(
          "\016\004\014\005\000\017myclient"
        )
      }.to raise_error(
        EventMachine::MQTTSN::ProtocolException,
        "Unsupported protocol ID number: 5"
      )
    end
  end
end

describe EventMachine::MQTTSN::Packet::Connack do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Connack.new
    expect(packet.type_id).to eq(0x05)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a sucessful connection acknowledgement packet" do
      packet = EventMachine::MQTTSN::Packet::Connack.new( :return_code => 0x00 )
      expect(packet.to_s).to eq("\x03\x05\x00")
    end
  end

  describe "when parsing a successful Connection Accepted packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x03\x05\x00" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Connack)
    end

    it "should set the return code of the packet correctly" do
      expect(@packet.return_code).to eq(0x00)
    end

    it "should set the return message of the packet correctly" do
      expect(@packet.return_msg).to match(/accepted/i)
    end
  end

  describe "when parsing a congestion packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x03\x05\x01" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Connack)
    end

    it "should set the return code of the packet correctly" do
      expect(@packet.return_code).to eq(0x01)
    end

    it "should set the return message of the packet correctly" do
      expect(@packet.return_msg).to match(/rejected: congestion/i)
    end
  end

  describe "when parsing a invalid topic ID packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x03\x05\x02" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Connack)
    end

    it "should set the return code of the packet correctly" do
      expect(@packet.return_code).to eq(0x02)
    end

    it "should set the return message of the packet correctly" do
      expect(@packet.return_msg).to match(/rejected: invalid topic ID/i)
    end
  end

  describe "when parsing a 'not supported' packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x03\x05\x03" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Connack)
    end

    it "should set the return code of the packet correctly" do
      expect(@packet.return_code).to eq(0x03)
    end

    it "should set the return message of the packet correctly" do
      expect(@packet.return_msg).to match(/not supported/i)
    end
  end

  describe "when parsing an unknown connection refused packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x03\x05\x10" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Connack)
    end

    it "should set the return code of the packet correctly" do
      expect(@packet.return_code).to eq(0x10)
    end

    it "should set the return message of the packet correctly" do
      expect(@packet.return_msg).to match(/rejected/i)
    end
  end
end


describe EventMachine::MQTTSN::Packet::Register do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Register.new
    expect(packet.type_id).to eq(0x0A)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a register packet" do
      packet = EventMachine::MQTTSN::Packet::Register.new(
        :id => 0x01,
        :topic_id => 0x01,
        :topic_name => 'test'
      )
      expect(packet.to_s).to eq("\x0A\x0A\x00\x01\x00\x01test")
    end
  end

  describe "when parsing a Register packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x0A\x0A\x00\x01\x00\x01test" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Register)
    end

    it "should set the topic id type of the packet correctly" do
      expect(@packet.topic_id_type).to eq(:normal)
    end

    it "should set the topic id of the packet correctly" do
      expect(@packet.topic_id).to eq(0x01)
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.id).to eq(0x01)
    end

    it "should set the topic name of the packet correctly" do
      expect(@packet.topic_name).to eq('test')
    end
  end
end


describe EventMachine::MQTTSN::Packet::Regack do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Regack.new
    expect(packet.type_id).to eq(0x0B)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a register packet" do
      packet = EventMachine::MQTTSN::Packet::Regack.new(
        :id => 0x02,
        :topic_id => 0x01,
        :return_code => 0x03
      )
      expect(packet.to_s).to eq("\x07\x0B\x00\x01\x00\x02\x03")
    end
  end

  describe "when parsing a REGACK packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x07\x0B\x00\x01\x00\x02\x03" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Regack)
    end

    it "should set the topic id type of the packet correctly" do
      expect(@packet.topic_id_type).to eq(:normal)
    end

    it "should set the topic id of the packet correctly" do
      expect(@packet.topic_id).to eq(0x01)
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.id).to eq(0x02)
    end

    it "should set the topic name of the packet correctly" do
      expect(@packet.return_code).to eq(0x03)
    end
  end
end


describe EventMachine::MQTTSN::Packet::Publish do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Publish.new
    expect(packet.type_id).to eq(0x0C)
  end

  describe "when serialising a packet with a normal topic id type" do
    it "should output the correct bytes for a publish packet" do
      packet = EventMachine::MQTTSN::Packet::Publish.new(
        :topic_id => 0x01,
        :topic_id_type => :normal,
        :data => "Hello World"
      )
      expect(packet.to_s).to eq("\x12\x0C\x00\x00\x01\x00\x00Hello World")
    end
  end

  describe "when serialising a packet with a short topic id type" do
    it "should output the correct bytes for a publish packet" do
      packet = EventMachine::MQTTSN::Packet::Publish.new(
        :topic_id => 'tt',
        :topic_id_type => :short,
        :data => "Hello World"
      )
      expect(packet.to_s).to eq("\x12\x0C\x02tt\x00\x00Hello World")
    end
  end

  describe "when parsing a Publish packet with a normal topic id" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse(
        "\x12\x0C\x00\x00\x01\x00\x00Hello World"
      )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Publish)
    end

    it "should set the QOS of the packet correctly" do
      expect(@packet.qos).to be === 0
    end

    it "should set the QOS of the packet correctly" do
      expect(@packet.duplicate).to be === false
    end

    it "should set the retain flag of the packet correctly" do
      expect(@packet.retain).to be === false
    end

    it "should set the topic id of the packet correctly" do
      expect(@packet.topic_id_type).to be === :normal
    end

    it "should set the topic id of the packet correctly" do
      expect(@packet.topic_id).to be === 0x01
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.id).to be === 0x0000
    end

    it "should set the topic name of the packet correctly" do
      expect(@packet.data).to eq("Hello World")
    end
  end

  describe "when parsing a Publish packet with a short topic id" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse(
        "\x12\x0C\x02tt\x00\x00Hello World"
      )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Publish)
    end

    it "should set the QOS of the packet correctly" do
      expect(@packet.qos).to be === 0
    end

    it "should set the QOS of the packet correctly" do
      expect(@packet.duplicate).to be === false
    end

    it "should set the retain flag of the packet correctly" do
      expect(@packet.retain).to be === false
    end

    it "should set the topic id type of the packet correctly" do
      expect(@packet.topic_id_type).to be === :short
    end

    it "should set the topic id of the packet correctly" do
      expect(@packet.topic_id).to be === 'tt'
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.id).to be === 0x0000
    end

    it "should set the topic name of the packet correctly" do
      expect(@packet.data).to eq("Hello World")
    end
  end
end


describe EventMachine::MQTTSN::Packet::Subscribe do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Subscribe.new
    expect(packet.type_id).to eq(0x12)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a Subscribe packet" do
      packet = EventMachine::MQTTSN::Packet::Subscribe.new(
        :duplicate => false,
        :qos => 0,
        :id => 0x02,
        :topic_name => 'test'
      )
      expect(packet.to_s).to eq("\x09\x12\x00\x00\x02test")
    end
  end

  describe "when parsing a Subscribe packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x09\x12\x00\x00\x03test" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Subscribe)
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.id).to eq(0x03)
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.qos).to eq(0)
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.duplicate).to eq(false)
    end

    it "should set the topic name of the packet correctly" do
      expect(@packet.topic_name).to eq('test')
    end
  end
end


describe EventMachine::MQTTSN::Packet::Suback do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Suback.new
    expect(packet.type_id).to eq(0x13)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a register packet" do
      packet = EventMachine::MQTTSN::Packet::Suback.new(
        :id => 0x02,
        :qos => 0,
        :topic_id => 0x01,
        :return_code => 0x03
      )
      expect(packet.to_s).to eq("\x08\x13\x00\x00\x01\x00\x02\x03")
    end
  end

  describe "when parsing a SUBACK packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse( "\x08\x13\x00\x00\x01\x00\x02\x03" )
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Suback)
    end

    it "should set the topic id of the packet correctly" do
      expect(@packet.qos).to eq(0)
    end

    it "should set the topic id type of the packet correctly" do
      expect(@packet.topic_id_type).to eq(:normal)
    end

    it "should set the topic id of the packet correctly" do
      expect(@packet.topic_id).to eq(0x01)
    end

    it "should set the message id of the packet correctly" do
      expect(@packet.id).to eq(0x02)
    end

    it "should set the topic name of the packet correctly" do
      expect(@packet.return_code).to eq(0x03)
    end
  end
end


describe EventMachine::MQTTSN::Packet::Pingreq do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Pingreq.new
    expect(packet.type_id).to eq(0x16)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a pingreq packet" do
      packet = EventMachine::MQTTSN::Packet::Pingreq.new
      expect(packet.to_s).to eq("\x02\x16")
    end
  end

  describe "when parsing a Pingreq packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse("\x02\x16")
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Pingreq)
    end
  end
end


describe EventMachine::MQTTSN::Packet::Pingresp do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Pingresp.new
    expect(packet.type_id).to eq(0x17)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a pingresp packet" do
      packet = EventMachine::MQTTSN::Packet::Pingresp.new
      expect(packet.to_s).to eq("\x02\x17")
    end
  end

  describe "when parsing a Pingresp packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse("\x02\x17")
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Pingresp)
    end
  end
end


describe EventMachine::MQTTSN::Packet::Disconnect do
  it "should have the right type id" do
    packet = EventMachine::MQTTSN::Packet::Disconnect.new
    expect(packet.type_id).to eq(0x18)
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a disconnect packet" do
      packet = EventMachine::MQTTSN::Packet::Disconnect.new
      expect(packet.to_s).to eq("\x02\x18")
    end
  end

  describe "when parsing a Disconnect packet" do
    before(:each) do
      @packet = EventMachine::MQTTSN::Packet.parse("\x02\x18")
    end

    it "should correctly create the right type of packet object" do
      expect(@packet.class).to eq(EventMachine::MQTTSN::Packet::Disconnect)
    end
  end
end
