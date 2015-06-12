require 'active_support/core_ext/class/attribute'

module ActionController
  module Serialization
    extend ActiveSupport::Concern

    include ActionController::Renderers

    # Deprecated
    ADAPTER_OPTION_KEYS = ActiveModel::SerializableResource::ADAPTER_OPTION_KEYS

    included do
      class_attribute :_serialization_scope
      self._serialization_scope = :current_user
    end

    def serialization_scope
      send(_serialization_scope) if _serialization_scope &&
        respond_to?(_serialization_scope, true)
    end

    def get_serializer(resource, options = {})
      if ! use_adapter?
        warn "ActionController::Serialization#use_adapter? has been removed. "\
          "Please pass 'adapter: false' or see ActiveSupport::SerializableResource#serialize"
        options[:adapter] = false
      end
      ActiveModel::SerializableResource.serialize(resource, options) do |serializable_resource|
        if serializable_resource.serializer?
          serializable_resource.serialization_scope ||= serialization_scope
          serializable_resource.serialization_scope_name = _serialization_scope
          begin
            serializable_resource.adapter
          rescue ActiveModel::Serializer::ArraySerializer::NoSerializerError
            resource
          end
        else
          resource
        end
      end
    end

    # Deprecated
    def use_adapter?
      true
    end

    [:_render_option_json, :_render_with_renderer_json].each do |renderer_method|
      define_method renderer_method do |resource, options|
        serializable_resource = get_serializer(resource, options)
        super(serializable_resource, options)
      end
    end

    # Tries to rescue the exception by looking up and calling a registered handler.
    #
    # Possibly Deprecated
    # TODO: Either Decorate 'exception' and define #handle_error where it is serialized
    # For example:
    #   class ExceptionModel
    #     include ActiveModel::Serialization
    #     def initialize(exception)
    #     # etc
    #   end
    #   def handle_error(exception)
    #     exception_model = ActiveModel::Serializer.build_exception_model({ errors: ['Internal Server Error'] })
    #     render json: exception_model, status: :internal_server_error
    #   end
    # OR remove method as it doesn't do anything right now.
    def rescue_with_handler(exception)
      super(exception)
    end

    module ClassMethods
      def serialization_scope(scope)
        self._serialization_scope = scope
      end
    end
  end
end
