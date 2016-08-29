require_relative '../helpers'

class CogCmd::Cfn::Template::List < Cog::SubCommand

  include CogCmd::Cfn::Helpers

  USAGE = <<~END
  Usage: cfn:template list

  Returns the list of templates in the configured s3 bucket.
  END

  def run
    s3 = Aws::S3::Client.new()

    s3.list_objects_v2(bucket: template_root[:bucket], prefix: template_root[:prefix])
    .contents
    .find_all { |obj|
      obj.key.end_with?(".json")
    }
    .map { |obj|
      { "name": strip_json(strip_prefix(obj.key)),
        "last_modified": obj.last_modified }
    }
  end
end
