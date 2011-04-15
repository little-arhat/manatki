# https://github.com/camlunity/kamlo_wiki/blob/master/Res.md

# https://github.com/neilconway/superators/commits/mri-19-compat

require 'superators'

module Kernel
  def fun(smb)
    return lambda { |*args|
      smb.to_proc.call(self, *args)
    }
  end
end


module Manatki

  module FailMonad

    class Manatka < Hash
      def bind(f)
        if self[:status] == :ok
          f.call(self[:value])
        else
          self
        end
      end

      superator ">>-" do |f|
        bind(f)
      end
    end

    def _(hsh)
      m = Manatki::FailMonad::Manatka.new
      m.merge!(hsh)
    end

    def ret(val)
      _({:status => :ok, :value => val})
    end

    def fail(e, opts={})
      _({:status => :err, :value => e}).merge(opts)
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

    def fmap(f)
      return lambda { |v|
        wrap(f, v)
      }
    end

    def catch(func, handler)
      res = func.call()
      if ok?(res)
        res
      else
        handler.call(res)
      end
    end

    def wrap(func, *args)
      _({:status => :ok, :value => func.call(*args)})
    rescue StandardError => exc
      _({:status => :error, :value => exc})
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

  module FunHelper
    def fun(smb, obj=self)
      return lambda { |*args|
        smb.to_proc.call(obj, *args)
      }
    end
  end

end

class Server
  include Manatki::FailMonad

  def f_connect(addr)
    raise StandardError
  end

  def s_connect(addr)
    "connected!"
  end

  def mult(smt)
    ret (smt * 5)
  end

  def process(addr, meth)
    wrap(fun(meth), addr) >>-
      lambda { |x| ret [x] } >>-
      lambda { |x|  ret x.first } >>-
      fun(:mult) >>- fmap(Kernel.fun(:p))

  end

  def f_process(addr)
    process(addr, :f_connect)
  end

  def s_process(addr)
    process(addr, :s_connect)
  end

end


def test
  addr = "caml.inria.fr"
  s = Server.new

  puts s.f_process(addr)
  puts s.s_process(addr)

end
