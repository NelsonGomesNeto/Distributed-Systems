using Distributed

addprocs(5)
println(procs())

@everywhere function print_worker_messages(message, worker_id)
  println("$worker_id: $message")
end

@everywhere function message_to_master(message)
  println("Sending to Master")
  me = myid()
  @spawnat 1 print_worker_messages("spawnat message", me)
  #          ^ daqui em diante, está no "ambiente" do o worker especificado (1)
  # por isso é necessário extrair o id antes; do contrário, seria passado o id 1

  remotecall(print_worker_messages, 1, "remotecall message", myid())
  # O @everywhere na função "print_worker_messages" é necessário para o remotecall
  # Mas não para o @spawnat, justamente por causa da observação anterior
end

@sync for w in workers()
  println("Asked $w")
  @spawnat w message_to_master("Miau")
end
# Se não colocar o sync, nem o spawnat, nem o remotecall funcionam; O Future é
# gerado sim, mas para forçar que sejam executados, é necessário explicitar.
# Talvez, por debaixo dos panos, o Jupyter obriga que os Futures terminem quando
# um bloco termina; mas não testei isso ainda