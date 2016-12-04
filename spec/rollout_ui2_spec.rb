require 'spec_helper'

describe RolloutUi2 do
  let(:rollout_instance) { Rollout.new(Store.new) }

  before { RolloutUi2.wrap(rollout_instance) }

  it 'has a version number' do
    expect(RolloutUi2::VERSION).not_to be nil
  end

  describe '.wrap' do
    let(:rollout_instance) { double(:rollout) }

    it { expect(RolloutUi2.wrap(rollout_instance)).to eq(rollout_instance) }
  end

  describe '.index' do
    context 'empy' do
      it { expect(RolloutUi2.index).to eq [] }
    end

    context 'with features' do
      before { rollout_instance.activate_percentage(:chat, 20) }

      it { expect(RolloutUi2.index).to match [RolloutUi2::Feature] }
    end
  end

  describe '.get' do
    subject { RolloutUi2.get("chat") }

    context 'empy' do
      describe '#percentage' do
        it { expect(subject.percentage).to eq 0 }
      end

      describe '#groups' do
        it { expect(subject.groups).to eq [] }
      end

      describe '#users' do
        it { expect(subject.users).to eq [] }
      end

      describe '#data' do
        it { expect(subject.data).to eq("{}\n").or eq(nil) }
      end
    end

    context 'with features' do
      before { rollout_instance.activate_percentage(:chat, 20) }

      describe '#percentage' do
        it { expect(subject.percentage).to eq 20.0 }
      end

      describe '#groups' do
        it { expect(subject.groups).to eq [] }
      end

      describe '#users' do
        it { expect(subject.users).to eq [] }
      end

      describe '#data' do
        it { expect(subject.data).to eq("{}\n").or eq(nil) }
      end
    end
  end

  describe '.save' do
    subject do
      feature = RolloutUi2.get("chat")
      feature.percentage = 50
      feature.groups = ["g", "h"]
      feature.users = ["u", "v"]
      RolloutUi2.save(feature)
      RolloutUi2.get("chat")
    end

    describe '#percentage' do
      it { expect(subject.percentage).to eq 50.0 }
    end

    describe '#groups' do
      it { expect(subject.groups).to eq [:g, :h] }
    end

    describe '#users' do
      it { expect(subject.users).to eq ["u", "v"] }
    end

    describe '#data' do
      it { expect(subject.data).to eq("{}\n").or eq(nil) }
    end
  end

  describe '.delete' do
    subject do
      feature = RolloutUi2.get("chat")
      feature.percentage = 50
      feature.groups = ["g", "h"]
      feature.users = ["u", "v"]
      RolloutUi2.save(feature)
      RolloutUi2.delete(feature)
      RolloutUi2.get("chat")
    end

    describe '#percentage' do
      it { expect(subject.percentage).to eq 0 }
    end

    describe '#groups' do
      it { expect(subject.groups).to eq [] }
    end

    describe '#users' do
      it { expect(subject.users).to eq [] }
    end

    describe '#data' do
      it { expect(subject.data).to eq("{}\n").or eq(nil) }
    end
  end
end
