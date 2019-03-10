/*  
Немного документации из Rx.NET с которой все скомуниздено:
Если что, смотреть сюда: https://github.com/Applied-Duality/Rx/tree/master/Rx/NET/Source/System.Reactive.Core/Reactive/Internal
 */
    
/// <summary>
/// Base class for implementation of query operators, providing a lightweight sink that can be disposed to mute the outgoing observer.
/// </summary>
/// <typeparam name="TSource">Type of the resulting sequence's elements.</typeparam>
/// <remarks>Implementations of sinks are responsible to enforce the message grammar on the associated observer. Upon sending a terminal message, a pairing Dispose call should be made to trigger cancellation of related resources and to mute the outgoing observer.</remarks>
internal abstract class Sink<TSource> : IDisposable
{
    protected internal volatile IObserver<TSource> _observer;
    private IDisposable _cancel;

    public Sink(IObserver<TSource> observer, IDisposable cancel)
    {
        _observer = observer;
        _cancel = cancel;
    }

    public virtual void Dispose()
    {
        _observer = NopObserver<TSource>.Instance;

        var cancel = Interlocked.Exchange(ref _cancel, null);
        if (cancel != null)
        {
            cancel.Dispose();
        }
    }

    public IObserver<TSource> GetForwarder()
    {
        return new _(this);
    }

    class _ : IObserver<TSource>
    {
        private readonly Sink<TSource> _forward;

        public _(Sink<TSource> forward)
        {
            _forward = forward;
        }

        public void OnNext(TSource value)
        {
            _forward._observer.OnNext(value);
        }

        public void OnError(Exception error)
        {
            _forward._observer.OnError(error);
            _forward.Dispose();
        }

        public void OnCompleted()
        {
            _forward._observer.OnCompleted();
            _forward.Dispose();
        }
    }
}


/// <summary>
/// Base class for implementation of query operators, providing performance benefits over the use of Observable.Create.
/// </summary>
/// <typeparam name="TSource">Type of the resulting sequence's elements.</typeparam>
internal abstract class Producer<TSource> : IProducer<TSource>
{
    /// <summary>
    /// Publicly visible Subscribe method.
    /// </summary>
    /// <param name="observer">Observer to send notifications on. The implementation of a producer must ensure the correct message grammar on the observer.</param>
    /// <returns>IDisposable to cancel the subscription. This causes the underlying sink to be notified of unsubscription, causing it to prevent further messages from being sent to the observer.</returns>
    public IDisposable Subscribe(IObserver<TSource> observer)
    {
        if (observer == null)
            throw new ArgumentNullException("observer");

        return SubscribeRaw(observer, true);
    }

    public IDisposable SubscribeRaw(IObserver<TSource> observer, bool enableSafeguard)
    {
        var state = new State();
        state.observer = observer;
        state.sink = new SingleAssignmentDisposable();
        state.subscription = new SingleAssignmentDisposable();

        var d = new CompositeDisposable(2) { state.sink, state.subscription };

        //
        // See AutoDetachObserver.cs for more information on the safeguarding requirement and
        // its implementation aspects.
        //
        if (enableSafeguard)
        {
            state.observer = SafeObserver<TSource>.Create(state.observer, d);
        }

        if (CurrentThreadScheduler.IsScheduleRequired)
        {
            CurrentThreadScheduler.Instance.Schedule(state, Run);
        }
        else
        {
            state.subscription.Disposable = this.Run(state.observer, state.subscription, state.Assign);
        }

        return d;
    }

    struct State
    {
        public SingleAssignmentDisposable sink;
        public SingleAssignmentDisposable subscription;
        public IObserver<TSource> observer;

        public void Assign(IDisposable s)
        {
            sink.Disposable = s;
        }
    }

    private IDisposable Run(IScheduler _, State x)
    {
        x.subscription.Disposable = this.Run(x.observer, x.subscription, x.Assign);
        return Disposable.Empty;
    }

    /// <summary>
    /// Core implementation of the query operator, called upon a new subscription to the producer object.
    /// </summary>
    /// <param name="observer">Observer to send notifications on. The implementation of a producer must ensure the correct message grammar on the observer.</param>
    /// <param name="cancel">The subscription disposable object returned from the Run call, passed in such that it can be forwarded to the sink, allowing it to dispose the subscription upon sending a final message (or prematurely for other reasons).</param>
    /// <param name="setSink">Callback to communicate the sink object to the subscriber, allowing consumers to tunnel a Dispose call into the sink, which can stop the processing.</param>
    /// <returns>Disposable representing all the resources and/or subscriptions the operator uses to process events.</returns>
    /// <remarks>The <paramref name="observer">observer</paramref> passed in to this method is not protected using auto-detach behavior upon an OnError or OnCompleted call. The implementation must ensure proper resource disposal and enforce the message grammar.</remarks>
    protected abstract IDisposable Run(IObserver<TSource> observer, IDisposable cancel, Action<IDisposable> setSink);
}