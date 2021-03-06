require_relative '../exceptions'

class CogCmd::Cfn::Changeset::List < Cog::Command

  USAGE = <<~END
  Usage: cfn:changeset list <stack name>

  Lists changesets for a stack. Returns a list of changeset summaries equivalent to resp.summaries documented here, http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#list_change_sets-instance_method
  END

  def run_command
    unless request.args[0]
      raise CogCmd::Cfn::ArgumentError, "You must specify the stack name."
    end

    client = Aws::CloudFormation::Client.new()

    stack_name = request.args[0]

    changesets = client.list_change_sets({ stack_name: stack_name })

    changesets.summaries.map(&:to_h)
  end

end
