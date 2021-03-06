require_relative '../exceptions'
require_relative '../helpers'

class CogCmd::Cfn::Changeset::Create < Cog::Command

  include CogCmd::Cfn::Helpers

  USAGE = <<~END
  Usage: cfn:changeset create <stack name> [options]

  Creates a changeset for a stack. Returns a map with changeset details.

  Options:
    --param, -p "Key1=Value1"               (Can be specified multiple times)
    --tag, -t "Name1=Value1"                (Can be specified multiple times)
    --template, -m "TemplateName"           (defaults to UsePreviousTemplate)
    --notify, -n "NotifyArn"                (Can be specified multiple times)
    --capabilities, -c <iam | named_iam>
    --description, -d "Description"
    --change-set-name "ChangeSetName"        (Defaults to 'changeset<num>')

  Examples:
    cfn:changeset create mystack --param "Key1=Value1" --param "Key2=Value2"
  END

  def run_command
    unless request.args[0]
      raise CogCmd::Cfn::ArgumentError, "You must specify the stack name."
    end

    client = Aws::CloudFormation::Client.new()

    stack_name = request.args[0]

    # If the user doesn't specify a change-set-name then we generate one based on the number
    # of changesets already created.
    unless request.options['change-set-name']
      # We just need the number of changesets already created so we can postfix the changeset name
      num_of_changesets = client.list_change_sets({ stack_name: stack_name }).summaries.length
      changeset_name = "changeset#{num_of_changesets}"
    else
      changeset_name = request.options['change-set-name']
    end

    template_summary = client.get_template_summary(stack_name: stack_name)

    cs_params = Hash[
      [
        [ :stack_name, stack_name ],
        [ :change_set_name, changeset_name ],
        [ :parameters, process_parameters(template_summary.parameters, request.options['param']) ],
        process_template(request.options['template']),
        param_or_nil([ :tags, process_tags(request.options['tag']) ]),
        param_or_nil([ :notification_arns, request.options['notify'] ]),
        param_or_nil([ :capabilities, process_capabilities(request.options['capabilities']) ]),
        param_or_nil([ :description, request.options['description'] ])
      ].compact
    ]

    resp = client.create_change_set(cs_params)
    client.describe_change_set(change_set_name: resp.id).to_h
  end

  private

  def process_template(template)
    # Checking the template name and setting it accordingly. If a user passes 'UsePreviousTemplate' they
    # should get their expected results now.
    scanner = StringScanner.new(template || '')
    template_name = scanner.match?(/UsePreviousTemplate/i) ? nil : request.options['template']

    if template_name
      [ :template_url, template_url(template_name) ]
    else
      [ :use_previous_template, true ]
    end
  end

  def process_parameters(template_params, params)
    params ||= []
    params = params.map do |p|
      param = p.strip.split("=")
      { parameter_key: param[0],
        parameter_value: param[1] }
    end

    template_params.map do |tp|
      param = { parameter_key: tp.parameter_key }

      if val = params.find { |p| p[:parameter_key] == tp.parameter_key }
        param[:parameter_value] = val[:parameter_value]
      else
        param[:use_previous_value] = true
      end

      param
    end
  end

end
