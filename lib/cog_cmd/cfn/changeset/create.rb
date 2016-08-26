class CogCmd::Cfn::Changeset < Cog::Command
  module Create

    USAGE = <<-END.gsub(/^ {4}/, '')
    Usage: cfn:changeset create <stack name> [options]

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

    Returns a map containing the id of the newly created changeset.
    END

  end

  def create(client, request)
    unless request.args[1]
      raise CogCmd::Cfn::ArgumentError, "You must specify the stack name."
    end

    stack_name = request.args[1]

    # If the user doesn't specify a change-set-name then we generate one based on the number
    # of changesets already created.
    unless request.options['change-set-name']
      # We just need the number of changesets already created so we can postfix the changeset name
      num_of_changesets = client.list_change_sets({ stack_name: stack_name }).summaries.length
      changeset_name = "changeset#{num_of_changesets}"
    else
      changeset_name = request.options['change-set-name']
    end

    cs_params = Hash[
      [
        [ :stack_name, stack_name ],
        [ :change_set_name, changeset_name ],
        process_template(request.options['template']),
        param_or_nil([ :parameters, process_parameters(request.options['param']) ]),
        param_or_nil([ :tags, process_tags(request.options['tag']) ]),
        param_or_nil([ :notification_arns, request.options['notify'] ]),
        param_or_nil([ :capabilities, process_capabilities(request.options['capabilities']) ]),
        param_or_nil([ :description, request.options['description'] ])
      ].compact
    ]

    client.create_change_set(cs_params).to_h
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
end