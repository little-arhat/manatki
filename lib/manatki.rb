# https://github.com/camlunity/kamlo_wiki/blob/master/Res.md

module Manatki
  class FailMonad
    def ret(val)
      {:status => :ok, :value => val}
    end

    def fail(e, opts={})
      {:status => :err, :value => e}.merge(opts)
    end

    def ok?(r)
      r[:status] == :ok
    end

    def bind(f, m)
      if m[:status] == :ok
        f.call(m[:value])
      else
        m
      end
    end
    # alias_method :>>=, :bind

    def catch(func, handler)
      res = func.call()
      if ok?(res)
        res
      else
        handler.call(res)
      end
    end

    def wrap(func, *args)
      {:status => :ok, :value => func.call(*args)}
    rescue StandardError => exc
      {:status => :error, :value => exc}
    end

    def catch_exn(func)
      func.call()
    rescue StandardError => exc
      fail exc
    end

    def catch_all(func, handler)
      catch lambda { catch_exn func }, handler
    end

    def exn_res(r)
      if ok?(r)
        r
      else
        raise r[:value]
      end
    end

    def map_err(f, r)
      if ok?(r)
        r
      else
        r[:value] = f.call(r[:value])
        r
      end
    end

    # def map_err(f, r)
    #   if !ok?(r)
    #     r[:value] = f.call(r[:value])
    #   end

    #   r
    # end

    def res_opterr(oe)
      if oe.nil?
        ret(nil)
      else
        fail(oe)
      end
    end

    def res_optval(ov)
      if ov.nil?
        fail(nil)
      else
        ret(ov)
      end
    end

  end
end
