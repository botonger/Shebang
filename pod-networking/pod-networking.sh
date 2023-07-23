#!/usr/bin/env bash

printWelcome() {
    while IFS= read -r line;
    do
      echo "$line";
      sleep 0.05
    done < welcome.txt
}

installTools() {
  read -p "ㄱ ㄱ ㄱ ㄱ" -s -n 1 key
  printf "\n\n네트워크 장치, 인터페이스, 터널, 라우팅 등 설정에 필요한 ip 명령어를 사용하기 위해"
  printf "\nnet-tools를 설치합니다!\n ....\n"
  sleep 0.5
  sudo apt-get update -y
  sudo apt-get install net-tools -y
}

# welcome message
printWelcome

#IP forwarding 활성화
printf "\nIP forwarding 활성화 중..."
sudo sysctl -w net.ipv4.ip_forward=1

# net-tools 설치
if ! [ -x "$(command -v ip)" ]; then
  installTools
else
  read -p "ㄱ ㄱ ㄱ ㄱ" -s -n 1 key
fi

# namespace 생성
printf "\n네트워크 네임스페이스 2개를 생성합니다..."
namespaces=()

echo
read -p "네임스페이스 이름 1: " ns1
read -p "네임스페이스 이름 2: " ns2
namespaces+=($ns1)
namespaces+=($ns2)

for ns in "${namespaces[@]}"
do
  sudo ip netns add "$ns"
done
echo
read -p ">> ip netns list" -s -n 1 key

# bridge 생성
#bridge_ip="192.168.2.0"
printf "\nbridge(가상 스위치)를 생성합니다..."
echo
read -p "bridge 이름: " bridge_name
read -p "bridge ip: " bridge_ip

sudo ip link add "$bridge_name" type bridge
sudo ip link set dev "$bridge_name" up
sudo ip addr add "$bridge_ip"/24 dev "$bridge_name"
echo
read -p ">> ip link" -s -n 1 key

# veth pair 생성
echo
read -p "가상 인터페이스 페어(veth pair)를 생성하고, (enter)" -s -n 1 key
for ns in "${namespaces[@]}"
do
  sudo ip link add veth-"$ns" type veth peer name veth-"${ns}"-br
done

echo
read -p "veth pair의 한쪽은 네임스페이스, 다른 쪽은 bridge에 연결합니다. (enter)" -s -n 1 key
for ns in "${namespaces[@]}"
do
  sudo ip link set veth-"$ns" netns "$ns"
  sudo ip link set veth-"$ns"-br master "$bridge_name"
  sudo ip link set veth-"$ns"-br up
  sudo ip -n "$ns" link set veth-"$ns" up
done
printf "\n>> ip link"
echo
read -p ">> sudo ip -n ${namespaces[0]} link" -s -n 1 key


echo
printf "\n각 veth에 ip를 할당합니다..."
echo
# veth1_ip="192.168.2.11/24"
# veth2_ip="192.168.2.12/24"
read -p "veth1_ip: " veth1_ip
read -p "veth2_ip: " veth2_ip

sudo ip -n "${namespaces[0]}" addr add "$veth1_ip" dev veth-"${namespaces[0]}"
sudo ip -n "${namespaces[1]}" addr add "$veth2_ip" dev veth-"${namespaces[1]}"
printf "\n>> sudo ip -n ${namespaces[0]} addr"
printf "\n>> sudo ip netns exec ${namespaces[0]} ping $(echo $veth2_ip | cut -d '/' -f2)"

host=$(hostname -I | awk '{print $1}')
echo
read -p ">> sudo ip netns exec ${namespaces[0]} ping $host" -s -n 1 key

echo
read -p "트래픽이 외부 네트워크로 나갈 수 있도록 라우팅 규칙을 추가합니다... (enter)" -s -n 1 key
for i in "${!namespaces[@]}"
do
  sudo ip -n "${namespaces[i]}" route add default via "$bridge_ip" dev veth-"${namespaces[i]}"
done
echo

