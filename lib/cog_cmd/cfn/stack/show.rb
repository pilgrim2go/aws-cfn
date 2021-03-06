require 'cog_cmd/cfn/helpers'

module CogCmd::Cfn::Stack
  class Show < Cog::Command

    include CogCmd::Cfn::Helpers

    attr_reader :stack_name

    def initialize
      @stack_name = request.args[0]
    end

    def run_command
      raise(Cog::Error, "You must specify a stack name.") unless stack_name

      response.template = 'stack_show'
      response.content = describe_stacks
    end

    private

    def describe_stacks
      client = Aws::CloudFormation::Client.new()
      client.describe_stacks(stack_name: stack_name).stacks[0].to_h
    end

  end
end
