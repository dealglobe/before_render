module BeforeRender
  extend ActiveSupport::Concern

  included do
    define_callbacks :render, terminator: ->(controller, result_lambda) { result_lambda.call if result_lambda.is_a?(Proc); controller.performed? },
                     skip_after_callbacks_if_terminated: true
  end

  def render(*args)
    run_callbacks(:render) do
      super
    end
  end

  module ClassMethods
    [:before, :after, :around].each do |callback|
      define_method "#{callback}_render" do |*names, &blk|
        _insert_callbacks(names, blk) do |name, options|
          set_callback(:render, callback, name, options)
        end
      end

      define_method "prepend_#{callback}_render" do |*names, &blk|
        _insert_callbacks(names, blk) do |name, options|
          set_callback(:render, callback, name, options.merge(prepend: true))
        end
      end

      # Skip a before, after or around callback. See _insert_callbacks
      # for details on the allowed parameters.
      define_method "skip_#{callback}_render" do |*names|
        _insert_callbacks(names) do |name, options|
          skip_callback(:render, callback, name, options)
        end
      end

      # *_action is the same as append_*_action
      alias_method :"append_#{callback}_render", :"#{callback}_render"
    end
  end

end

AbstractController::Callbacks.include BeforeRender
