require File.expand_path('../../spec_helper', __FILE__)

describe file('/srv/node/1') do
  it do
    should be_mounted.with(
      :type    => 'xfs',
      :options => {
        :rw   => true,
      }
    )
  end
end

describe file('/srv/node/2') do
  it do
    should be_mounted.with(
      :type    => 'xfs',
      :options => {
        :rw   => true,
      }
    )
  end
end
