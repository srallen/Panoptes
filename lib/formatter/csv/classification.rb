module Formatter
  module Csv
    class Classification
      attr_reader :classification, :project, :obfuscate, :salt

      delegate :workflow, :workflow_id, :created_at, :gold_standard,
        :workflow_version, to: :classification

      def self.project_headers
        %w( user_name user_ip workflow_id workflow_name workflow_version
            created_at gold_standard expert metadata annotations subject_data )
      end

      def initialize(project, obfuscate_private_details: true)
        @project = project
        @obfuscate = obfuscate_private_details
        @salt = Time.now.to_i
      end

      def to_array(classification)
        @classification = classification
        self.class.project_headers.map do |attribute|
          send(attribute)
        end
      end

      private

      def user_name
        if user = classification.user
          user.login
        else
          "not-logged-in-#{hash_value(classification.user_ip.to_s)}"
        end
      end

      def user_ip
        obfuscate_value(classification.user_ip.to_s)
      end

      def subject_data
        {}.tap do |subjects_and_metadata|
          subjects = ::Subject.where(id: classification.subject_ids)
          subjects.each do |subject|
            retired_data = { retired: subject.retired_for_workflow?(workflow.id) }
            subjects_and_metadata[subject.id] = subject.metadata.merge(retired_data)
          end
        end.to_json
      end

      def metadata
        classification.metadata.to_json
      end

      def annotations
        classification.annotations.map do |annotation|
          annotation = annotation.dup
          _, task = classification.workflow.tasks.find {|key, task| key == annotation["task"] }

          if task && task["type"] == "drawing"
            annotation["value"] = annotation["value"].map do |drawn_item|
              tool = task["tools"][drawn_item["tool"]]
              tool_label = classification.workflow.workflow_content_for_primary_language.strings[tool["label"]]
              drawn_item.merge "tool_label" => tool_label
            end
          end

          annotation
        end.to_json
      end

      def expert
        classification.expert_classifier
      end

      def workflow_name
        workflow.display_name
      end

      def obfuscate_value(value)
        obfuscate ? hash_value(value) : value
      end

      def hash_value(value)
        Digest::SHA1.hexdigest("#{value}#{salt}")
      end
    end
  end
end
