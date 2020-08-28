defimpl Jason.Encoder, for: PID do 
  def encode(value, opts) do
    Jason.Encode.string(inspect(value), opts)
  end
end
