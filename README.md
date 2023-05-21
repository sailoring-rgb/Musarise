<h1 style="font-size:80px" align="center"><img height=28cm src="docImages/logo.png"> Musarise</h1>

<p align="center">Uma aplicação <i>IOS</i> que traz toda a experiência de produção de uma música até você!</p> 

<p align="center">
<a href="https://formulae.brew.sh/formula/semgrep">
<img src="https://img.shields.io/badge/Swift-5.5-orange" alt="Homebrew" />
</a>
</p>

<h2> Features </h2>

* [📱 Rede social](#redeSocial)
* [🎵 Instrumentos](#instrumentos)

<a name="redeSocial"><h2>📱 Rede social</h2></a>

- <h4>Registo da conta e *login*</h4>

Ao registrar uma conta na aplicação, o utilizador deve fornecer os seguintes dados pessoais: (1) o *email*, (2) o *username* e (3) a senha. Opcionalmente, é possível adicionar uma foto de perfil. No momento do *login*, o utilizador pode escolher inserir o seu *email* ou o *username*, juntamente com a senha. Existem duas situações de erro que ocorrem quando já existe uma conta com o *email*, ou o nome de usuário, introduzido, e quando a palavra-passe fornecida está incorreta, respectivamente.

- <h4>Perfil de um usuário</h4>

Para além das informações pessoais fornecidas durante o registo da conta, a página de perfil de um utilizador exibe o número total de publicações feitas por ele, bem como *links* para o número de seguidores e de contas seguidas, que mostram exatamente esses indivíduos. A página apresenta, ainda, todos *posts* feitos pelo usuário em questão. Quando se trata do perfil de outro usuário, a lista de publicações é apresentada como "Their Posts". No entanto, quando se trata do perfil do próprio usuário, a lista é denominada por "My Posts". É possível chegar ao perfil de outro usuário de diversas maneiras, nomeadamente através da opção de pesquisa.

- <h4>Criação de uma publicação</h4>

A criação de um *post* pode incluir texto, imagem ou áudio. Contudo, ao adicionar um áudio previamente armazenado na garagem de sons que o usuário criou, é obrigatório também adicionar uma imagem. Isto porque, essa imagem servirá como um género de *cover* para o áudio.

- <h4>Características de uma publicação</h4>

Após ser compartilhada com os demais membros da aplicação, a publicação assume a sua forma completa, composta pelo seu conteúdo, pelo *username* e pelo *icon* do usuário que a criou, juntamente com a data e hora em que foi publicada. Ao clicar na identificação do criador, a página é redirecionada para o perfil dele. Além dessas características, há também uma secção de *likes* e comentários, onde aqueles que têm acesso ao *post* -- <ins>os seguidores do criador</ins>, podem interagir e fornecer seu *feedback*. Ao carregar na capa do áudio, a aplicação é redirecionada para a página com a *waveform* do áudio. Esta página tem como imagem de fundo a capa do som publicado, mostrando também a descrição da publicação. 

- <h4>Registo dos valores do giroscópio para treinar modelos</h4>

A rede social oferece, adicionalmente, um modo de captura de valores gerados pelo giroscópio, visando a sua utilização para o aprimoramento da sensorização. Como cobaia, temos a guitarra virtual da *Musarise* que, ao carregar no botão localizado no canto inferior esquerdo, o utilizador pode decidir o momento exato em que os dados devem começar a ser registados. A consequência dessa ação é a mudança de cor da tela para sinalizar o acontecimento e a contribuição para um melhor funcionamento da aplicação.

- <h4>Gravação e armazenamento do som</h4>

Depois de produzir um som, o utilizador não é obrigado a publicar o resultado final. Em vez disso, ele tem a opção de gravar e guardar a sua criação na sua biblioteca de áudios, para posterior audição e, quem sabe, compartilhamento com os seus seguidores. O formulário para salvar o resultado final permite que sejam atribuídos um título e uma descrição.

- <h4>Participação em desafios musicais</h4>

 A *Musarise* ambiciona entreter aqueles que usufruem dela, mas, acima de tudo, motivar e inspirar os amantes da música. Surgiu, assim, a ideia de desafiar os usuários a recriar sons bastante conhecidos. Basta consultar a página onde estão divulgados esses desafios e mergulhar na diversão que a música proporciona.

<a name="instrumentos"><h2>🎵 Instrumentos</h2></a>

### Bateria

O **sensor acelerómetro** é utilizado para criar o som da **bateria**. Esse sensor mede as acelerações do dispositivo em diferentes direções, permitindo detetar o momento em que a batida é tocada e a intensidade dos golpes dados na bateria virtual. A aplicação disponibiliza 5 tipos de sons diferentes -- 1 *floor tom*, 1 *rack tom* e 2 *crash cymbal*, todos extraídos a partir da plataforma *online* [Virtual Drumming](https://www.virtualdrumming.com/drums/online-virtual-games/online-virtual-games-drums.html).

A estratégia adotada para a reprodução do som da bateria baseia-se na análise da variação do sinal da aceleração, tendo em conta a sua polaridade. No processo de execução, quando a baqueta começa o seu movimento descendente em direção ao instrumento, os valores da aceleração são registados como positivos. No entanto, à medida que se aproxima do ponto de impacto, ocorre uma transição para valores negativos, sendo este intervalo crucial para determinar o volume sonoro. Quanto mais rápido for esse intervalo de tempo em que a aceleração é negativa, maior será a intensidade resultante. Este intervalo termina assim que aceleração voltar a ser positiva, representando este o momento em que a baqueta se eleva e se afasta do instrumento. A figura seguinte ilustra a posição que o dispositivo deve assumir para a concretização do processo descrito.

![Texto alternativo da imagem](docImages/battery.png)

No contexto da bateria virtual, existem dois modos possíveis de reprodução: o modo simples e o modo livre. No <ins>modo simples</ins>, é apenas tocado um dos 5 sons disponíveis ao longo da simulação. Em contrapartida, o <ins>no modo livre</ins>, já não inclui uma seleção pré-definida de um som. Em vez disso, existem 3 partes da bateria em posições diferentes. A ideia é que, ao mover-se mais para a direita, esquerda ou centro, o resultado gerado varia de acordo com a tal parte do instrumento que se encontra nessa posição. Esta abordagem proporciona uma experiência mais realista e expressiva à simulação.

### Guitarra

O sensor giroscópio é utilizado para a criação do som da guitarra. Tal sensor mede a taxa de variação na qual um dispositivo gira em torno de um eixo espacial. Ou seja, é medida a velocidade angular do dispositivo. Os valores de rotação são medidos em radianos por segundo em torno do eixo específico. Os valores de rotação podem ser positivos ou negativos, dependendo da direção da rotação.  O movimento considerado para a simulação da guitarra foi aquele que é gerado pela mão que segura a palheta. Isto é, a aplicação reproduz a mão que realiza o "ritmo" do som.  A figura seguinte mostra o movimento de rotação simulado pela aplicação.

![Texto alternativo da imagem](docImages/guitar.png)


Para produzir o som da guitarra, foram consideradas as seis notas correspondentes às cordas soltas (Mi, Lá, Ré, Sol, Si e Mi), tocadas individualmente, sem a formação de acordes. É como se apenas a mão do "ritmo" fosse considerada. Os sons de cada nota foram obtidos a partir da plataforma [Recursive Arts](https://recursivearts.com/online-guitar/).

O mecanismo por trás da reprodução dos sons das notas segue o seguinte princípio: *a intensidade da variação da rotação reflete na quantidade de notas tocadas*. Quanto maior a variação obtida, mais notas são emitidas. Deste modo, foi preciso apenas determinar qual seria a variação detectada que iria corresponder a reprodução das seis notas de uma vez. A partir deste valor, através de uma regra de três simples, pode-se  obter o número de notas que devem ser reproduzidas a partir da variação de rotação atual. 

As seis notas são armazenadas numa lista (seguindo a ordem "de cima para baixo" da guitarra). Para além disto, é também conhecida a última nota tocada. Assim, a partir do mecanismo de obtenção da **quantidade de notas a serem tocadas** juntamente com a **direção do movimento**, podemos saber quais as notas que devem ser tocadas (acessando **n** notas a frente ou anterioriores a última nota tocada) e de seguida atualizar a última nota reproduzida. 

### Piano

O **sensor de *touch*** é usado para recolher o toque do usuário nas 6 teclas virtuais do piano. Os sons de cada tecla foram conseguidos através da plataforma [Recursive Arts](https://recursivearts.com/virtual-piano/). Quanto mais suave for o toque, melhor será a resposta às variações de pressão exercidas e, consequentemente, mais precisa será a sequência de sons produzida. Esta funcionalidade é preciosa para aspirantes a pianista que, com a capacidade de se expressarem musicalmente através de um toque, podem criar uma experiência interessante de tocar piano.

![Texto alternativo da imagem](docImages/piano.png)

### Voice

O **sensor do microfone** é utilizado para a captação do áudio do utilizador. Quanto mais perto da boca do utilizador, melhor as ondas sonoras são captadas pelo sensor. O objetivo desta *feature* é permitir o utilizador sentir-se como o cantor de uma banda.

![Texto alternativo da imagem](docImages/voice.png)

<h2> 👥 Equipa </h2>


- <a href="https://github.com/sailoring-rgb">Ana Henriques</a>
- <a href="https://github.com/LittleLevi05">Henrique Costa</a>
