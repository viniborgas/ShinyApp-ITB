library(shiny)
library(openxlsx)
library(tidyverse)
library(imputeTS)
library(writexl)
library(DT)
library(shinythemes)
library(readxl)
#library(shinyShortcut)

### Funções
### Função para formatar os Websites ###
domain <- function(x) {as.character(strsplit(gsub("http://|https://|www\\.|pt\\-br\\.|\\•", "", x), " "))}

### Função para separar os nomes ###
fml <- function(mangled_names) {
  titles <- c("MASTER", "MR", "MISS", "MRS", "MS",
              "MX", "JR", "SR", "M", "SIR", "GENTLEMAN",
              "SIRE", "MISTRESS", "MADAM", "DAME", "LORD",
              "LADY", "ESQ", "EXCELLENCY","EXCELLENCE",
              "HER", "HIS", "HONOUR", "THE",
              "HONOURABLE", "HONORABLE", "HON", "JUDGE")
  mangled_names %>% sapply(function(name) {
    split <- str_split(name, " ") %>% unlist
    original_length <- length(split)
    split <- split[which(!split %>%
                           toupper %>%
                           str_replace_all('[^A-Z]','')
                         %in% titles)]
    case_when(
      (length(split) < original_length) &
        (length(split) == 1) ~ c(NA,
                                 NA,
                                 split[1]),
      length(split) == 1 ~ c(split[1],NA,NA),
      length(split) == 2 ~ c(split[1],NA,
                             split[2]),
      length(split) == 3 ~ c(split[1],
                             split[2],
                             split[3]),
      length(split) > 3 ~ c(split[1],
                            paste(split[2:(length(split)-1)],
                                  collapse = "-"),
                            split[length(split)])
    )
  }) %>% t %>% return
}

ui <- {navbarPage(theme = shinythemes::shinytheme("spacelab"),
                  title = "Scripts",
                  tabPanel("Data Desktop",
                           titlePanel("Ajuste da base do Data Desktop"),
                           sidebarPanel(width = 3,
                                        helpText("Faça o upload do arquivo em .xlsx"),
                                        fileInput('base_DD', 'Escolha o arquivo',
                                                  accept=c(".xlsx")),
                                        downloadButton('Download_DD', 'Download')),
                           mainPanel(
                             tabsetPanel(
                               tabPanel("Dados Cadastrais", DT::dataTableOutput("Dados_Cadastrais")),
                               tabPanel("Sócios", DT::dataTableOutput("Socios")))))
                  ,
                  
                  
                  tabPanel("Cortex Data Desktop Plus",
                           titlePanel("Ajuste das bases extraídas do Cortex Data Desktop Plus"),
                           sidebarPanel(width = 3,
                                        helpText("Upload da extração bruta em .xlsx"),
                                        fileInput('base_dados_cadastrais_CDDP', 'DADOS CADASTRAIS',
                                                  accept=c(".xlsx")),
                                        h2(),
                                        
                                        downloadButton('Download_dados_cadastrais_CDDP', 'Download Dados Cadastrais'),
                                        h2(),
                                        
                                        fileInput('base_contatos_CDDP', 'CONTATOS',
                                                  accept=c(".xlsx")),
                                        
                                        downloadButton('Download_contatos_CDDP', 'Download Contatos'),
                                        h2(),
                                        
                                        fileInput('base_linkedin_CDDP', 'LINKEDIN',
                                                  accept=c(".xlsx")),
                                        
                                        downloadButton('Download_linkedin_CDDP', 'Download LinkedIn'),
                                        h2(),
                                        helpText("O Download do arquivo LinkedIn contém duas abas, uma contendo os contatos e outra contendo as empresas."),
                                        h2(),
                                        
                                        fileInput('base_BR2_CDDP', 'Módulo BR2',
                                                  accept=c(".xlsx")),
                                        
                                        downloadButton('Download_BR2_CDDP', 'Download BR2'),
                                        h2(),
                                        helpText("O Download do arquivo BR2 contém duas abas, uma contendo os dados cadastrais e outra contendo os sócios.")),
                           mainPanel(
                             tabsetPanel(
                               tabPanel("Dados Cadastrais", DT::dataTableOutput("Dados_Cadastrais_CDDP")),
                               tabPanel("Contatos", DT::dataTableOutput("Contatos_CDDP")),
                               
                               
                               
                               tabPanel("LinkedIn - Contatos", DT::dataTableOutput("contatos_LinkedIn_CDDP")),
                               
                               
                               
                               tabPanel("LinkedIn - Empresas", DT::dataTableOutput("empresas_LinkedIn_CDDP")),
                               
                               
                               
                               tabPanel("BR2 - Dados Cadastrais", DT::dataTableOutput("BR2_Dados_Cadastrais_CDDP")),
                               
                               
                               
                               tabPanel("BR2 - Sócios", DT::dataTableOutput("BR2_Socios_CDDP")))))
                  ,
                  
                  
                  tabPanel("Apollo",
                           titlePanel("Ajuste base de contatos Apollo"),
                           sidebarPanel(width = 3,
                                        helpText("Upload da extração bruta em .csv"),
                                        fileInput('base_contatos_apollo', 'CONTATOS',
                                                  accept=c(".csv")),
                                        downloadButton('Download_contatos_Apollo', 'Download Contatos'),
                                        h2(),
                                        
                                        fileInput('base_empresas_apollo', 'EMPRESAS',
                                                  accept=c(".csv")),
                                        downloadButton('Download_empresas_Apollo', 'Download Empresas')),
                           mainPanel(
                             tabsetPanel(
                               tabPanel("Contatos Apollo", DT::dataTableOutput("Contatos_Apollo")),
                               tabPanel("Empresas Apollo", DT::dataTableOutput("Empresas_Apollo")))))
                  ,
                  
                  
                  tabPanel("Intricately",
                           titlePanel("Ajuste do Output do Intricately"),
                           sidebarPanel(width = 3,
                                        helpText("Faça o upload do arquivo em .csv"),
                                        fileInput('base_Intricately', 'Escolha o arquivo',
                                                  accept=c(".csv")),
                                        downloadButton('Download_Intricately', 'Download')),
                           mainPanel(
                             tabsetPanel(
                               tabPanel("Intricately", DT::dataTableOutput("Intricately")))))
                  ,
                  
                  
                  tabPanel("ITDM Finder",
                           titlePanel("Categoriza os cargos dos contatos"),
                           sidebarPanel(width = 3,
                                        tags$h5("O processamento não demanda um template específico, mas a coluna com os cargos deve se chamar 'CARGO B2B'."),
                                        h2(),
                                        tags$h5("Serão adicionadas 3 colunas à base:"),
                                        tags$h5("- 'MATCHING DECISORES' sinalizando cargos de decisores, independente da área;"),
                                        tags$h5("- 'MATCHING BLACKLIST DE AREAS' sinalizando cargos que não pertencem às áreas de TI;"),
                                        tags$h5("- 'MATCHING AREAS DE IT' sinalizando cargos das áreas de TI."),
                                        h2(),
                                        fileInput('base_ITDM', 'Escolha o arquivo',
                                                  accept=c(".xlsx")),
                                        downloadButton('Download_ITDM', 'Download')),
                           mainPanel(
                             tabsetPanel(
                               tabPanel("ITDM", DT::dataTableOutput("ITDM")))))
                  ,
                  
                  
                  tabPanel("Left JoineR",
                           titlePanel("Executa um Left Join simples"),
                           sidebarPanel(width = 3,
                                        tags$h5("Dados à esquerda"),
                                        h2(),
                                        fileInput('base_esquerda', 'Escolha o arquivo',
                                                  accept=c(".xlsx")),
                                        h2(),
                                        tags$h5("Dados à direita"),
                                        h2(),
                                        fileInput('base_direita', 'Escolha o arquivo',
                                                  accept=c(".xlsx")),
                                        h2(),
                                        textInput('colunas_join', "Chave Primária:", value = "CNPJ"),
                                        h2(),
                                        downloadButton('Download_Left_JoineR', 'Download')),
                           mainPanel(
                             tabsetPanel(
                               tabPanel("Left_JoineR", DT::dataTableOutput("Left_JoineR")))))
)}

server <- function(input, output) {
  
  ### IMPORTAÇÕES
  ### Importa base do DD
  base_DD <- reactive({
    
    validate(need(input$base_DD != "", "Faça o upload do arquivo em .xlsx"))
    
    filein <- input$base_DD
    
    if (is.null(input$base_DD))
      return(NULL)
    
    openxlsx::read.xlsx(input$base_DD$datapath, colNames = TRUE)
    
  })
  
  ### Importa base de Dados Cadastrais do CDDP
  base_Dados_Cadastrais_CDDP <- reactive({
    
    validate(need(input$base_dados_cadastrais_CDDP != "", "Faça o upload do arquivo em .xlsx"))
    
    filein <- input$base_dados_cadastrais_CDDP
    
    if (is.null(input$base_dados_cadastrais_CDDP))
      return(NULL)
    
    openxlsx::read.xlsx(input$base_dados_cadastrais_CDDP$datapath, colNames = TRUE)
    
  })
  
  ### Importa base de Contatos do CDDP
  base_Contatos_CDDP <- reactive({
    
    validate(need(input$base_contatos_CDDP != "", "Faça o upload do arquivo em .xlsx"))
    
    filein <- input$base_contatos_CDDP
    
    if (is.null(input$base_contatos_CDDP))
      return(NULL)
    
    openxlsx::read.xlsx(input$base_contatos_CDDP$datapath, colNames = TRUE)
    
  })
  
  ### Importa base de LinkedIn do CDDP
  base_LinkedIn_CDDP <- reactive({
    
    validate(need(input$base_linkedin_CDDP != "", "Faça o upload do arquivo em .xlsx"))
    
    filein <- input$base_linkedin_CDDP
    
    if (is.null(input$base_linkedin_CDDP))
      return(NULL)
    
    openxlsx::read.xlsx(input$base_linkedin_CDDP$datapath, colNames = TRUE)
    
  })
  
  ### Importa base de LinkedIn do CDDP
  base_BR2_DC_CDDP <- reactive({
    
    validate(need(input$base_BR2_CDDP != "", "Faça o upload do arquivo em .xlsx"))
    
    filein <- input$base_BR2_CDDP
    
    if (is.null(input$base_BR2_CDDP))
      return(NULL)
    
    openxlsx::read.xlsx(input$base_BR2_CDDP$datapath, colNames = TRUE, sheet = "Resultados")
    
  })
  
  ### Importa base de LinkedIn do CDDP
  base_BR2_Socios_CDDP <- reactive({
    
    validate(need(input$base_BR2_CDDP != "", "Faça o upload do arquivo em .xlsx"))
    
    filein <- input$base_BR2_CDDP
    
    if (is.null(input$base_BR2_CDDP))
      return(NULL)
    
    openxlsx::read.xlsx(input$base_BR2_CDDP$datapath, colNames = TRUE, sheet = "Adicionais")
    
  })
  
  ### Importa base de contatos do Apollo
  base_contatos_apollo <- reactive({
    
    validate(need(input$base_contatos_apollo != "", "Faça o upload da base bruta em .csv"))
    
    filein <- input$base_contatos_apollo
    
    if (is.null(input$base_contatos_apollo))
      return(NULL)
    
    readr::read_csv(input$base_contatos_apollo$datapath , col_names = TRUE, locale = readr::locale(encoding = "UTF-8"))
    
  })
  
  ### Importa base de empresas do Apollo
  base_empresas_apollo <- reactive({
    
    validate(need(input$base_empresas_apollo != "", "Faça o upload da base bruta em .csv"))
    
    filein <- input$base_empresas_apollo
    
    if (is.null(input$base_empresas_apollo))
      return(NULL)
    
    readr::read_csv(input$base_empresas_apollo$datapath , col_names = TRUE, locale = readr::locale(encoding = "UTF-8"))
    
  })
  
  ### Importa base de tecnologias Intricately
  base_Intricately <- reactive({
    
    validate(need(input$base_Intricately != "", "Faça o upload da base bruta em .csv"))
    
    filein <- input$base_Intricately
    
    if (is.null(input$base_Intricately))
      return(NULL)
    
    readr::read_csv(input$base_Intricately$datapath , col_names = TRUE, locale = readr::locale(encoding = "UTF-8"))
    
  })
  
  ### Importa base de Contatos para ITDM Finder
  base_ITDM <- reactive({
    
    validate(need(input$base_ITDM != "", "Faça o upload da base bruta em .xlsx"))
    
    filein <- input$base_ITDM
    
    if (is.null(input$base_ITDM))
      return(NULL)
    
    openxlsx::read.xlsx(input$base_ITDM$datapath, colNames = TRUE)
    
  })
  
  ### Importa base esquerda para Left JoineR
  base_esquerda <- reactive({
    
    validate(need(input$base_esquerda != "", "Faça o upload da base bruta em .xlsx"))
    
    filein <- input$base_esquerda
    
    if (is.null(input$base_esquerda))
      return(NULL)
    
    readxl::read_excel(input$base_esquerda$datapath, col_names = TRUE)
    
  })
  
  ### Importa base direita para Left JoineR
  base_direita <- reactive({
    
    validate(need(input$base_direita != "", "Faça o upload da base bruta em .xlsx"))
    
    filein <- input$base_direita
    
    if (is.null(input$base_direita))
      return(NULL)
    
    readxl::read_excel(input$base_direita$datapath, col_names = TRUE)
    
  })
  
  ###TRATAMENTO
  ### Trata Dados Cadastrais do DD
  Dados_Cadastrais <- reactive({
    
    base <- base_DD()
    
    ### Separa aba Dados Cadastrais ###
    dados_cadastrais <- base %>% select("Código.CNPJ",
                                        "Razão.social",
                                        "Nome.fantasia",
                                        "Logradouro",
                                        "Numero",
                                        "Complemento",
                                        "Bairro",
                                        "Cidade",
                                        "UF",
                                        "CEP",
                                        "Porte",
                                        "Capital.Social.até",
                                        "Faturamento.até",
                                        "Quantidade.de.funcionários.até",
                                        "Data.da.abertura",
                                        "Tipo.de.unidade",
                                        "Tipo.situação",
                                        "Tipo.Enquadramento.Porte",
                                        "Código.atividade.econômica.primária",
                                        "Nome.atividade.econômica.primária",
                                        "Código.da.natureza.jurídica",
                                        "Nome.natureza.jurídica.geral",
                                        "E-mail.na.Receita.Federal",
                                        "Tipo.de.classificação.jurídica",
                                        "Website1",
                                        "Website2",
                                        "Website3",
                                        "Website4",
                                        "Website5",
                                        "Telefone.1",
                                        "Telefone.2",
                                        "Telefone.3",
                                        "Telefone.4",
                                        "Telefone.5") %>%
      rename("CNPJ" = "Código.CNPJ",
             "RAZÃO SOCIAL" = "Razão.social",
             "NOME FANTASIA" = "Nome.fantasia",
             "LOGRADOURO" = "Logradouro",
             "NUMERO" = "Numero",
             "COMPLEMENTO" = "Complemento",
             "BAIRRO" = "Bairro",
             "CIDADE" = "Cidade",
             "UF" = "UF",
             "CEP" = "CEP",
             "PORTE" = "Porte",
             "FAIXA DE CAPITAL SOCIAL" = "Capital.Social.até",
             "FAIXA DE FATURAMENTO" = "Faturamento.até",
             "FAIXA DE FUNCIONÁRIOS" = "Quantidade.de.funcionários.até",
             "DATA DA ABERTURA" = "Data.da.abertura",
             "TIPO DE UNIDADE" = "Tipo.de.unidade",
             "TIPO SITUAÇÃO" = "Tipo.situação",
             "TIPO ENQUADRAMENTO PORTE" = "Tipo.Enquadramento.Porte",
             "CÓDIGO ATIVIDADE ECONÔMICA PRIMÁRIA" = "Código.atividade.econômica.primária",
             
             
             
             "NOME ATIVIDADE ECONÔMICA PRIMÁRIA" = "Nome.atividade.econômica.primária",
             
             
             
             "CÓDIGO DA NATUREZA JURÍDICA" = "Código.da.natureza.jurídica",
             "NOME NATUREZA JURÍDICA GERAL" = "Nome.natureza.jurídica.geral",
             "E-MAIL NA RECEITA FEDERAL" = "E-mail.na.Receita.Federal",
             "TIPO DE CLASSIFICAÇÃO JURÍDICA" = "Tipo.de.classificação.jurídica",
             "WEBSITE1" = "Website1",
             "WEBSITE2" = "Website2",
             "WEBSITE3" = "Website3",
             "WEBSITE4" = "Website4",
             "WEBSITE5" = "Website5",
             "TELEFONE1" = "Telefone.1",
             "TELEFONE2" = "Telefone.2",
             "TELEFONE3" = "Telefone.3",
             "TELEFONE4" = "Telefone.4",
             "TELEFONE5" = "Telefone.5")
    
    ### Ordena alfabeticamente e remove duplicados ###
    dados_cadastrais <- dados_cadastrais %>% arrange(`RAZÃO SOCIAL`) %>% distinct(CNPJ, .keep_all = TRUE)
    
    ### transforma faixas em numeric ###
    dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` <- dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` %>% str_remove_all("\\.") %>% str_remove_all(",") %>% as.numeric()/100 %>% as.numeric()
    dados_cadastrais$`FAIXA DE FATURAMENTO` <- dados_cadastrais$`FAIXA DE FATURAMENTO` %>% str_remove_all("\\.") %>% str_remove_all(",") %>% as.numeric()/100 %>% as.numeric()
    dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` <- dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` %>% str_remove_all("\\.") %>% as.numeric()
    
    ### Substitui nulos pela méda ###
    dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` <- na_mean(dados_cadastrais$`FAIXA DE CAPITAL SOCIAL`)
    dados_cadastrais$`FAIXA DE FATURAMENTO` <- na_mean(dados_cadastrais$`FAIXA DE FATURAMENTO`)
    dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` <- na_mean(dados_cadastrais$`FAIXA DE FUNCIONÁRIOS`)
    
    ### Ranges ###
    Rmonet <- c(0,50000,
                250000,500000,
                2500000,10000000,
                50000000,100000000,
                250000000,500000000,
                1000000000,1000000000000)
    Lmonet <- c('R$ 0 - R$ 50 K',
                'R$ 51 K - R$ 250 K',
                'R$ 251 K - R$ 500 K',
                'R$ 501 K - R$ 2.5 M',
                'R$ 2.5 M - R$ 10 M',
                'R$ 10 M - R$ 50 M',
                'R$ 50 M - R$ 100 M','R$ 100 M - R$ 250 MI',
                'R$ 250 M - R$ 500 MI',
                'R$ 500 M - R$ 1 B',
                '+ R$ 1 B')
    Rfunc <- c(0,3,10,
               50,200,
               500,1000,
               5000,10000,
               100000)
    Lfunc <- c('0 - 3',
               '4 - 10',
               '11 - 50',
               '51 - 200',
               '201 - 500',
               '501 - 1.000',
               '1.001 - 5.000',
               '5.001 - 10.000',
               '+ 10.000')
    
    ### Transforma em Ranges ###
    dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` <- dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` %>% cut(Rmonet, Lmonet)
    dados_cadastrais$`FAIXA DE FATURAMENTO` <- dados_cadastrais$`FAIXA DE FATURAMENTO` %>% cut(Rmonet, Lmonet)
    
    
    
    dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` <- dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` %>% cut(Rfunc, Lfunc)
    
    ### Ajusta Telefones ###
    dados_cadastrais$TELEFONE1 <- dados_cadastrais$TELEFONE1 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    dados_cadastrais$TELEFONE2 <- dados_cadastrais$TELEFONE2 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$TELEFONE3 <- dados_cadastrais$TELEFONE3 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$TELEFONE4 <- dados_cadastrais$TELEFONE4 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$TELEFONE5 <- dados_cadastrais$TELEFONE5 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$WEBSITE1 <- dados_cadastrais$WEBSITE1 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE2 <- dados_cadastrais$WEBSITE2 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE3 <- dados_cadastrais$WEBSITE3 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE4 <- dados_cadastrais$WEBSITE4 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE5 <- dados_cadastrais$WEBSITE5 %>% gsub(pattern = ",", replacement = ".")
    
    dados_cadastrais <- dados_cadastrais %>% mutate_all(.funs=toupper)
    
    as.data.frame(dados_cadastrais)
    
  })
  
  ### Trata Sócios do DD
  Socios <- reactive({
    
    base <- base_DD()
    
    ### Separa dfs de sócios ###
    socios1 <- base %>% select("Código.CNPJ", "Razão.social", "Nome.do.sócio.1", "Qualificação.sócio.1", "Tipo.qualificação.sócio.1") %>%
      rename("CNPJ"="Código.CNPJ", "RAZÃO SOCIAL"="Razão.social", "NOME DO SÓCIO"="Nome.do.sócio.1", "QUALIFICAÇÃO SÓCIO"="Qualificação.sócio.1", "TIPO QUALIFICAÇÃO SÓCIO"="Tipo.qualificação.sócio.1")
    socios2 <- base %>% select("Código.CNPJ", "Razão.social", "Nome.do.sócio.2", "Qualificação.sócio.2", "Tipo.qualificação.sócio.2") %>%
      rename("CNPJ"="Código.CNPJ", "RAZÃO SOCIAL"="Razão.social", "NOME DO SÓCIO"="Nome.do.sócio.2", "QUALIFICAÇÃO SÓCIO"="Qualificação.sócio.2", "TIPO QUALIFICAÇÃO SÓCIO"="Tipo.qualificação.sócio.2")
    socios3 <- base %>% select("Código.CNPJ", "Razão.social", "Nome.do.sócio.3", "Qualificação.sócio.3", "Tipo.qualificação.sócio.3") %>%
      rename("CNPJ"="Código.CNPJ", "RAZÃO SOCIAL"="Razão.social", "NOME DO SÓCIO"="Nome.do.sócio.3", "QUALIFICAÇÃO SÓCIO"="Qualificação.sócio.3", "TIPO QUALIFICAÇÃO SÓCIO"="Tipo.qualificação.sócio.3")
    socios4 <- base %>% select("Código.CNPJ", "Razão.social", "Nome.do.sócio.4", "Qualificação.sócio.4", "Tipo.qualificação.sócio.4") %>%
      rename("CNPJ"="Código.CNPJ", "RAZÃO SOCIAL"="Razão.social", "NOME DO SÓCIO"="Nome.do.sócio.4", "QUALIFICAÇÃO SÓCIO"="Qualificação.sócio.4", "TIPO QUALIFICAÇÃO SÓCIO"="Tipo.qualificação.sócio.4")
    socios5 <- base %>% select("Código.CNPJ", "Razão.social", "Nome.do.sócio.5", "Qualificação.sócio.5", "Tipo.qualificação.sócio.5") %>%
      rename("CNPJ"="Código.CNPJ", "RAZÃO SOCIAL"="Razão.social", "NOME DO SÓCIO"="Nome.do.sócio.5", "QUALIFICAÇÃO SÓCIO"="Qualificação.sócio.5", "TIPO QUALIFICAÇÃO SÓCIO"="Tipo.qualificação.sócio.5")
    
    ### Empilha sócios e filtra NAs ###
    socios <- bind_rows(socios1, socios2, socios3, socios4, socios5) %>% drop_na(`NOME DO SÓCIO`)
    
    ### Ajusta Nomes para Proper Case e exclui numeração da Qualificação do sócio ###
    socios$`NOME DO SÓCIO` <- str_to_title(socios$`NOME DO SÓCIO`, locale = "en")
    socios$`QUALIFICAÇÃO SÓCIO` <- socios$`QUALIFICAÇÃO SÓCIO` %>% gsub(pattern = '^.+?-(.*)', replacement = "\\1")
    
    socios
    
  })
  
  ### Trata Dados Cadastrais do CDDP
  Dados_Cadastrais_CDDP <- reactive({
    
    ### Nomes das colunas ###
    #cols <- c('CNPJ', 'RAZÃO SOCIAL', 'NOME FANTASIA', 'LOGRADOURO', 'NUMERO', 'COMPLEMENTO', 'BAIRRO', 'CIDADE', 'UF', 'CEP', 'PORTE', 'FAIXA DE CAPITAL SOCIAL', 'FAIXA DE FATURAMENTO', 'FAIXA DE FUNCIONÁRIOS', 'DATA DA ABERTURA', 'TIPO DE UNIDADE', 'TIPO SITUAÇÃO', 'TIPO ENQUADRAMENTO PORTE', 'CÓDIGO ATIVIDADE ECONÔMICA PRIMÁRIA', 'NOME ATIVIDADE ECONÔMICA PRIMÁRIA', 'CÓDIGO DA NATUREZA JURÍDICA', 'NOME NATUREZA JURÍDICA GERAL', 'E-MAIL NA RECEITA FEDERAL', 'TIPO DE CLASSIFICAÇÃO JURÍDICA', 'WEBSITE1', 'WEBSITE2', 'WEBSITE3', 'WEBSITE4', 'WEBSITE5', 'TELEFONE1', 'TELEFONE2', 'TELEFONE3', 'TELEFONE4', 'TELEFONE5')
    
    Rmonet <- c(0,50000,
                250000,500000,
                2500000,10000000,
                50000000,100000000,
                250000000,500000000,
                1000000000,1000000000000)
    Lmonet <- c('R$ 0 - R$ 50 K',
                'R$ 51 K - R$ 250 K',
                'R$ 251 K - R$ 500 K',
                'R$ 501 K - R$ 2.5 M',
                'R$ 2.5 M - R$ 10 M',
                'R$ 10 M - R$ 50 M',
                'R$ 50 M - R$ 100 M','R$ 100 M - R$ 250 MI',
                'R$ 250 M - R$ 500 MI',
                'R$ 500 M - R$ 1 B',
                '+ R$ 1 B')
    
    base <- as.data.frame(base_Dados_Cadastrais_CDDP())
    
    ### Cria df com colunas
    dados_cadastrais_CDDP <- base %>%
      mutate(CNPJ = base$QUERY,
             `RAZÃO SOCIAL` = toupper(base$`RAZAO.SOCIAL`),
             `NOME FANTASIA` = toupper(base$`NOME.FANTASIA`),
             LOGRADOURO = toupper(paste(base$`TIPO.LOGRADOURO`, base$LOGRADOURO)),
             NUMERO = base$NUMERO,
             COMPLEMENTO = toupper(base$COMPLEMENTO),
             BAIRRO = toupper(base$BAIRRO),
             CIDADE = toupper(base$MUNICIPIO),
             UF = toupper(base$UF),
             CEP = paste0(substr(base$CEP,1, 2), ".", substr(base$CEP, 3, 5), "-", substr(base$CEP, 6, nchar(base$CEP))),
             PORTE = NA,
             `FAIXA DE CAPITAL SOCIAL` = as.numeric(base$`CAPITAL.SOCIAL`) %>% cut(Rmonet, Lmonet),
             `FAIXA DE FATURAMENTO` = base$`RECEITA.ESTIMADA.UNIDADE`,
             `FAIXA DE FUNCIONÁRIOS` = base$`NUMERO.FUNCIONARIOS.UNIDADE`,
             `DATA DA ABERTURA` = base$`DATA.ABERTURA`,
             `TIPO DE UNIDADE` = NA,
             `TIPO SITUAÇÃO` = toupper(base$STATUS),
             `TIPO ENQUADRAMENTO PORTE` = NA,
             `CÓDIGO ATIVIDADE ECONÔMICA PRIMÁRIA` = paste0(substr(base$`CNAE.PRINCIPAL.CODIGO`, 1, 4), "-", substr(base$`CNAE.PRINCIPAL.CODIGO`, 5, 5), "/", substr(base$`CNAE.PRINCIPAL.CODIGO`,6,7)), #REVER CNAE
             `NOME ATIVIDADE ECONÔMICA PRIMÁRIA` = toupper(base$`CNAE.PRINCIPAL.DESCRICAO`),
             `CÓDIGO DA NATUREZA JURÍDICA` = NA,
             `NOME NATUREZA JURÍDICA GERAL` = NA,
             `E-MAIL NA RECEITA FEDERAL` = NA,
             `TIPO DE CLASSIFICAÇÃO JURÍDICA` = NA,
             WEBSITE1 = domain(tolower(base$WEBSITE)),
             WEBSITE2 = NA,
             WEBSITE3 = NA,
             WEBSITE4 = NA,
             WEBSITE5 = NA,
             TELEFONE1 = paste0("+55",base$DDD, base$TELEFONE),
             TELEFONE2 = NA,
             TELEFONE3 = NA,
             TELEFONE4 = NA,
             TELEFONE5 = NA) %>%
      select(CNPJ, `RAZÃO SOCIAL`, `NOME FANTASIA`, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, CIDADE, UF, CEP, PORTE, `FAIXA DE CAPITAL SOCIAL`, `FAIXA DE FATURAMENTO`, `FAIXA DE FUNCIONÁRIOS`, `DATA DA ABERTURA`, `TIPO DE UNIDADE`, `TIPO SITUAÇÃO`, `TIPO ENQUADRAMENTO PORTE`, `CÓDIGO ATIVIDADE ECONÔMICA PRIMÁRIA`, `NOME ATIVIDADE ECONÔMICA PRIMÁRIA`, `CÓDIGO DA NATUREZA JURÍDICA`, `NOME NATUREZA JURÍDICA GERAL`, `E-MAIL NA RECEITA FEDERAL`, `TIPO DE CLASSIFICAÇÃO JURÍDICA`, WEBSITE1, WEBSITE2, WEBSITE3, WEBSITE4, WEBSITE5, TELEFONE1, TELEFONE2, TELEFONE3, TELEFONE4, TELEFONE5) %>%
      drop_na(`RAZÃO SOCIAL`)
    
    as.data.frame(dados_cadastrais_CDDP)
    
  })
  
  ### Trata Contatos do CDDP
  contatos_CDDP <- reactive({
    
    cols <- c("DOMÍNIO", "PRIMEIRO NOME", "ULTIMO NOME", "CARGO B2B", "EMAIL", "URL LINKEDIN PESSOAL")
    base <- base_Contatos_CDDP()
    
    contatos_CDDP <- base %>% select(QUERY, first_name, last_name, job_title, business_email, social_url) %>%
      set_names(cols) %>%
      mutate(`URL LINKEDIN PESSOAL` = `URL LINKEDIN PESSOAL` %>%
               str_replace("false", " ") %>%
               str_replace("FALSE", " ") %>%
               domain())
    
    contatos_CDDP
    
  })
  
  ### Trata Contatos LinkedIn do CDDP
  contatos_linkedin_CDDP <- reactive({
    
    cols <- c("DOMÍNIO", "PRIMEIRO NOME", "ULTIMO NOME", "CARGO B2B", "EMAIL", "URL LINKEDIN PESSOAL")
    base <- base_LinkedIn_CDDP()
    
    contatos_linkedin_CDDP <- base %>%
      select(Query, Nome, Cargo, Email, Linkedin_contato) %>%
      add_column("First" = NA) %>%
      add_column("Middle" = NA) %>%
      add_column("Last" = NA)
    
    contatos_linkedin_CDDP[,c("First", "Middle", "Last")] <- contatos_linkedin_CDDP$Nome %>% fml
    contatos_linkedin_CDDP <- contatos_linkedin_CDDP %>% select(Query, First, Last, Cargo, Email, Linkedin_contato) %>%
      mutate(Linkedin_contato = domain(Linkedin_contato)) %>%
      set_names(cols)
    
    contatos_linkedin_CDDP
    
  })
  
  ### Trata empresas LinkedIn do CDDP
  empresas_linkedin_CDDP <- reactive({
    
    cols_emp <- c('WEBSITE', "NOME FANTASIA", "INDUSTRIA", "PALAVRAS CHAVE", "URL LINKEDIN", "URL FACEBOOK", "URL TWITTER", "CRUNCHBASE URL", "DESCRIÇÃO EMPRESA", "NUMERO DE FUNCIONÁRIOS", "FATURAMENTO", "SEGMENTO", "CIDADE", "PAIS", "TECNOLOGIAS")
    base <- base_LinkedIn_CDDP()
    
    empresas_linkedin_CDDP <- base %>%
      select(Query, Nome_empresa, Industria, Palavras_chave, Linkedin, Facebook, Twitter, Crunchbase, Descricao_empresa, N_funcionarios, Faturamento, Segmento, Regiao, Pais, Tecnologias) %>%
      mutate(Linkedin = domain(Linkedin),
             Facebook = domain(Facebook),
             Twitter = domain(Twitter),
             Crunchbase = domain(Crunchbase)) %>%
      set_names(cols_emp) %>%
      distinct(WEBSITE, .keep_all = TRUE)
    
    empresas_linkedin_CDDP
    
  })
  
  ### Trata Dados Cadastrais do BR2 CDDP
  BR2_Dados_Cadastrais <- reactive({
    
    base <- base_BR2_DC_CDDP()
    
    ### Separa aba Dados Cadastrais ###
    dados_cadastrais <- base %>% select("Código.CNPJ",
                                        "Razão.social",
                                        "Nome.fantasia",
                                        "Logradouro",
                                        "Numero",
                                        "Complemento",
                                        "Bairro",
                                        "Cidade",
                                        "UF",
                                        "CEP",
                                        "Porte",
                                        "Capital.Social.até",
                                        "Faturamento.até",
                                        "Quantidade.de.funcionários.até",
                                        "Data.da.abertura",
                                        "Tipo.de.unidade",
                                        "Tipo.situação",
                                        "Tipo.Enquadramento.Porte",
                                        "Código.atividade.econômica.primária",
                                        "Nome.atividade.econômica.primária",
                                        "Código.da.natureza.jurídica",
                                        "Nome.natureza.jurídica.geral",
                                        "E-mail.na.Receita.Federal",
                                        "Tipo.de.classificação.jurídica",
                                        "Website1",
                                        "Website2",
                                        "Website3",
                                        "Website4",
                                        "Website5",
                                        "Telefone.1",
                                        "Telefone.2",
                                        "Telefone.3",
                                        "Telefone.4",
                                        "Telefone.5") %>%
      rename("CNPJ" = "Código.CNPJ",
             "RAZÃO SOCIAL" = "Razão.social",
             "NOME FANTASIA" = "Nome.fantasia",
             "LOGRADOURO" = "Logradouro",
             "NUMERO" = "Numero",
             "COMPLEMENTO" = "Complemento",
             "BAIRRO" = "Bairro",
             "CIDADE" = "Cidade",
             "UF" = "UF",
             "CEP" = "CEP",
             "PORTE" = "Porte",
             "FAIXA DE CAPITAL SOCIAL" = "Capital.Social.até",
             "FAIXA DE FATURAMENTO" = "Faturamento.até",
             "FAIXA DE FUNCIONÁRIOS" = "Quantidade.de.funcionários.até",
             "DATA DA ABERTURA" = "Data.da.abertura",
             "TIPO DE UNIDADE" = "Tipo.de.unidade",
             "TIPO SITUAÇÃO" = "Tipo.situação",
             "TIPO ENQUADRAMENTO PORTE" = "Tipo.Enquadramento.Porte",
             "CÓDIGO ATIVIDADE ECONÔMICA PRIMÁRIA" = "Código.atividade.econômica.primária",
             
             
             
             "NOME ATIVIDADE ECONÔMICA PRIMÁRIA" = "Nome.atividade.econômica.primária",
             
             
             
             "CÓDIGO DA NATUREZA JURÍDICA" = "Código.da.natureza.jurídica",
             "NOME NATUREZA JURÍDICA GERAL" = "Nome.natureza.jurídica.geral",
             "E-MAIL NA RECEITA FEDERAL" = "E-mail.na.Receita.Federal",
             "TIPO DE CLASSIFICAÇÃO JURÍDICA" = "Tipo.de.classificação.jurídica",
             "WEBSITE1" = "Website1",
             "WEBSITE2" = "Website2",
             "WEBSITE3" = "Website3",
             "WEBSITE4" = "Website4",
             "WEBSITE5" = "Website5",
             "TELEFONE1" = "Telefone.1",
             "TELEFONE2" = "Telefone.2",
             "TELEFONE3" = "Telefone.3",
             "TELEFONE4" = "Telefone.4",
             "TELEFONE5" = "Telefone.5")
    
    ### Ordena alfabeticamente e remove duplicados ###
    dados_cadastrais <- dados_cadastrais %>% arrange(`RAZÃO SOCIAL`) %>% distinct(CNPJ, .keep_all = TRUE)
    
    ### transforma faixas em numeric ###
    dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` <- dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` %>% str_remove_all("\\.") %>% str_remove_all(",") %>% as.numeric()/100 %>% as.numeric()
    dados_cadastrais$`FAIXA DE FATURAMENTO` <- dados_cadastrais$`FAIXA DE FATURAMENTO` %>% str_remove_all("\\.") %>% str_remove_all(",") %>% as.numeric()/100 %>% as.numeric()
    dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` <- dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` %>% str_remove_all("\\.") %>% as.numeric()
    
    ### Substitui nulos pela méda ###
    dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` <- na_mean(dados_cadastrais$`FAIXA DE CAPITAL SOCIAL`)
    dados_cadastrais$`FAIXA DE FATURAMENTO` <- na_mean(dados_cadastrais$`FAIXA DE FATURAMENTO`)
    dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` <- na_mean(dados_cadastrais$`FAIXA DE FUNCIONÁRIOS`)
    
    ### Ranges ###
    Rmonet <- c(0,50000,
                250000,500000,
                2500000,10000000,
                50000000,100000000,
                250000000,500000000,
                1000000000,1000000000000)
    Lmonet <- c('R$ 0 - R$ 50 K',
                'R$ 51 K - R$ 250 K',
                'R$ 251 K - R$ 500 K',
                'R$ 501 K - R$ 2.5 M',
                'R$ 2.5 M - R$ 10 M',
                'R$ 10 M - R$ 50 M',
                'R$ 50 M - R$ 100 M','R$ 100 M - R$ 250 MI',
                'R$ 250 M - R$ 500 MI',
                'R$ 500 M - R$ 1 B',
                '+ R$ 1 B')
    Rfunc <- c(0,3,10,
               50,200,
               500,1000,
               5000,10000,
               100000)
    Lfunc <- c('0 - 3',
               '4 - 10',
               '11 - 50',
               '51 - 200',
               '201 - 500',
               '501 - 1.000',
               '1.001 - 5.000',
               '5.001 - 10.000',
               '+ 10.000')
    
    ### Transforma em Ranges ###
    dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` <- dados_cadastrais$`FAIXA DE CAPITAL SOCIAL` %>% cut(Rmonet, Lmonet)
    dados_cadastrais$`FAIXA DE FATURAMENTO` <- dados_cadastrais$`FAIXA DE FATURAMENTO` %>% cut(Rmonet, Lmonet)
    
    
    
    dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` <- dados_cadastrais$`FAIXA DE FUNCIONÁRIOS` %>% cut(Rfunc, Lfunc)
    
    ### Ajusta Telefones ###
    dados_cadastrais$TELEFONE1 <- dados_cadastrais$TELEFONE1 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    dados_cadastrais$TELEFONE2 <- dados_cadastrais$TELEFONE2 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$TELEFONE3 <- dados_cadastrais$TELEFONE3 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$TELEFONE4 <- dados_cadastrais$TELEFONE4 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$TELEFONE5 <- dados_cadastrais$TELEFONE5 %>% gsub(pattern = "\\(", replacement = "+55") %>%
      gsub(pattern = "\\)", replacement = "") %>%
      gsub(pattern = " ", replacement = "") %>%
      gsub(pattern = "-", replacement = "")
    
    dados_cadastrais$WEBSITE1 <- dados_cadastrais$WEBSITE1 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE2 <- dados_cadastrais$WEBSITE2 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE3 <- dados_cadastrais$WEBSITE3 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE4 <- dados_cadastrais$WEBSITE4 %>% gsub(pattern = ",", replacement = ".")
    dados_cadastrais$WEBSITE5 <- dados_cadastrais$WEBSITE5 %>% gsub(pattern = ",", replacement = ".")
    
    dados_cadastrais <- dados_cadastrais %>% mutate_all(.funs=toupper)
    
    as.data.frame(dados_cadastrais)
    
  })
  
  ### Trata Contatos do Apollo
  Contatos_Apollo <- reactive({
    
    cols <- c('RAZÃO SOCIAL','WEBSITE','PRIMEIRO NOME','ULTIMO NOME', 'CARGO B2B', 'E-MAIL','LINKEDIN PESSOAL URL','TECNOLOGIAS', 'Company Linkedin Url','Facebook Url','Twitter Url')
    
    base <- base_contatos_apollo()
    
    contatos_apollo <- base %>% select('Company',
                                       'Website',
                                       'First Name',
                                       'Last Name',
                                       'Title','Email',
                                       'Person Linkedin Url',
                                       'Technologies',
                                       'Company Linkedin Url',
                                       'Facebook Url',
                                       'Twitter Url') %>% ### Seleciona as colunas
      setNames(cols) %>% ### Renomeia as colunas
      mutate(WEBSITE = domain(WEBSITE),
             WEBSITE = str_replace(WEBSITE, "character\\(0\\)", " "),
             `LINKEDIN PESSOAL URL` = domain(`LINKEDIN PESSOAL URL`),
             `LINKEDIN PESSOAL URL` = str_replace(`LINKEDIN PESSOAL URL`, "character\\(0\\)", " "),
             `Company Linkedin Url` = domain(`Company Linkedin Url`),
             `Company Linkedin Url` = str_replace(`Company Linkedin Url`, "character\\(0\\)", " "),
             `Facebook Url` = domain(`Facebook Url`),
             `Facebook Url` = str_replace(`Facebook Url`, "character\\(0\\)", " "),
             `Twitter Url` = domain(`Twitter Url`),
             `Twitter Url` = str_replace(`Twitter Url`, "character\\(0\\)", " "),
             `CARGO B2B` = toupper(`CARGO B2B`)) %>% ### trata os websites e coloca cargos em maiúsculo
      filter(!grepl("ESTAG", `CARGO B2B`)) %>% ### Remove cargos de estagiário
      as.data.frame()
    
    contatos_apollo
    
  })
  
  ### Trata Empresas do Apollo
  Empresas_Apollo <- reactive({
    
    base <- base_empresas_apollo()
    
    empresas_Apollo <- base %>% select('Website',
                                       'Company',
                                       'Industry',
                                       'Company Linkedin Url',
                                       'Facebook Url',
                                       'Twitter Url',
                                       'Keywords',
                                       'SEO Description',
                                       'Technologies') %>% ### Seleciona as colunas ### Renomeia as colunas
      mutate(Website = domain(Website),
             Website = str_replace(Website, "character\\(0\\)", " "),
             `Company Linkedin Url` = domain(`Company Linkedin Url`),
             `Company Linkedin Url` = str_replace(`Company Linkedin Url`, "character\\(0\\)", " "),
             `Facebook Url` = domain(`Facebook Url`),
             `Facebook Url` = str_replace(`Facebook Url`, "character\\(0\\)", " "),
             `Twitter Url` = domain(`Twitter Url`),
             `Twitter Url` = str_replace(`Twitter Url`, "character\\(0\\)", " ")) %>% ### trata os websites
      as.data.frame()
    
    empresas_Apollo
    
  })
  
  ### Trata Intricately
  Intricately <- reactive({
    
    base <- base_Intricately()
    
    intricately <- base %>%
      mutate(`Intricately URL` = domain(`Intricately URL`),
             `LinkedIn Profile` = domain(`LinkedIn Profile`),
             `SAAS PRODUCTS (COUNT)` = str_count(`SaaS Products`, ";") + 1)
    
    intricately
    
  })
  
  ### Trata Intricately
  ITDM <- reactive({
    
    cargos_dm <- c("ADMIN|ADMINISTRADOR|ASSOCIATE|\\bCEO\\b|\\bCFO\\b|\\bCHIEF\\b|\\bCIO\\b|\\bCISO\\b|C-LEVEL|\\bCMO\\b|\\bCOO\\b|\\bCOORD|\\bCSO\\b|\\bCTO\\b|DIRECTOR|DIRETOR|ENCARREGADO|FOUNDER|FUNDADOR|GERENTE|HEAD|LEAD|LEADER|LIDER|LÍDER|MANAGER|OWNER|PARTNER|PRESIDENT|PRINCIPAL|\\bPROPRIET|SENIOR|SÊNIOR|SOCI|SÓCI|SPECIAL|SR|SUPERINTENDENT|SUPERVISOR|TECH LEAD|TECHNICAL|TECNICO|TÉCNICO|VICE PRESIDENT|VICE PRESIDENTE|VICE-PRESIDENT|VP")
    blacklist <- c("ACCOUNT MANAGER|BUSINESS DEVELOPMENT|ENGENHEIRO|IMPOSTO|TAXA|TRIBUTO|ORÇAMENTO|INVESTIMENTO|CREDITO|COMPLIANCE|AUDITORIA|CUSTOS|PRODUTO|RISCOS|PLANEJAMENTO|CONTROLADORIA|CONTROLES INTERNOS|FUSÃO|AQUISIÇÃO|FISCAL|CONTABILIDADE|TESOURARIA|CFO|FINANCAS|BENEFICIOS|REMUNERAÇÃO|DESENVOLVIMENTO|TREINAMENTO|DEPARTAMENTO PESSOAL|SELECAO|RECRUTAMENTO|RECURSOS HUMANOS|WEB ANALYTICS|E-MAIL|BRANDING|BRAND|\\bSEO\\b|ONLINE|PUBLICIDADE|DEVELOPMENT|SOCIAL MEDIA|REDES SOCIAIS|MULTIMEDIA|MEDIA|CONTEUDO|LOJA ONLINE|WEBSITE|E-COMMERCE|INBOUND MARKETING|UX|EVENTO|\\bDIGITAL\\b|\\bCMO\\b|\\bMARKETING\\b|OPERACAO|MAQUINARIO|\\bCOO\\b|SUPLY CHAIN|ESTOQUE|LOGISTICA|OPERACOES|COMERCIAL|REPRESENTANTE COMERCIAL|COMERCIAL|ASSISTENTE COMERCIAL|PROMOTOR|SALES DEVELOPMENT|SDR|INTELIGENCIA COMERCIAL|GERENTE COMERCIAL|\\bCSO\\b|\\bCOO\\b|\\bCFO\\b|DIRETOR COMERCIAL|INBOUND SALES|INSIDE SALES|EXPERIENCIA DO CLIENTE|CUSTOMER EXPERIENCE|CS|CUSTOMER SUCCESS|POS VENDA|PRÉ VENDA|VENDA|REPRESENTANTE DE VENDA|REPRESENTANTE|VENDEDOR|CONTA|ACCOUNT MANAGER")
    IT_Keywords <- c("\\bAI\\b|ANALYTICS|ANDROID|APPLICATION|ARTIFICIAL|BACKEND|BACK-END|BANCO DE DADOS|\\bBI\\b|BIG DATA|BUSINESS INTELLIGENCE|CIÊNCIA DE DADOS|CIENCIA DE DADOS|DATA SCIENTIST|CIENTISTA DE DADOS|\\bCIO\\b|\\bCISO\\b|CLOUD|COMPUTER|COMPUTING|\\bCPD\\b|\\bCTO\\b|DADOS|DATA|DATA SCIENCE|DATA WAREHOUSE|DATABASE|DATACENTER|DESENVOLVEDOR|DESK|\\bDEV\\b|DEVELOPER|DEVOPS|\\bERP\\b|FRONTEND|FRONT-END|FULLSTACK|FULL-STACK|HARDWARE|\\bIA\\b|INFORMAÇÃO|INFORMATION|INFRA|INFRASTRUCTURE|INFRAESTRUTURA|INTELIGÊNCIA ARTIFICIAL|INTELIGENCIA ARTIFICIAL|INTELLIGENCE|INTERNET|\\bIOT\\b|\\bI.T.\\b|\\bI.T\\b|\\bIT\\b|MOBILE|NETWORK|PLATAFORMA|PLATFORM|PRODUCT|PRODUTO|PROGRAM|PROGRAMA|PROGRAMMING|PROGRAMAÇÃO|PROGRAMACAO|PROGRAMADOR|PROGRAMMER|PROJECT|PROJETOS|QUALIDADE DE SOFTWARE|QUALITY ASSURANCE|\\bREDE\\b|REDES|SCRUM|SECURITY|SEGURANÇA|SEGURANÇA DA INFORMAÇÃO|SISTEMA|SISTEMAS|SOFTWARE|SOLUTION|SUPORTE|SUPPORT|SYSTEM|\\bT.I\\b|\\bT.I.\\b|TECH|TECH LEAD|TECHLONOGY|TECHNOLOGY|TECNOLOGIA|\\bTI\\b|\\bUI\\b|USER DESIGN|USER EXPERIENCE|\\bUX\\b|\\bWEB\\b")
    isolados <- c('DIRETOR', 'DIRECTOR', 'DIRETORA', 'MANAGER', 'GERENTE', 'GERENTE ', 'COORDENADOR', 'COORDENADOR ', 'COORDINATOR', 'COORDENADORA', 'COORDENADORA ', 'PRESIDENTE', 'PRESIDENTE ', 'FOUNDER', 'FUNDADOR', 'VICE PRESIDENTE', 'VICE-PRESIDENTE', 'SUPERINTENDENTE', 'OWNER', 'CEO', 'CEO ', 'CHIEF EXECUTIVE OFFICER', 'HEAD')
    
    base <- base_ITDM()
    names(base) <-   gsub(x = names(base), pattern = "\\.", replacement = " ")
    
    ITDM <- base %>%
      mutate(`CARGO B2B` = toupper(`CARGO B2B`),
             `MATCHING DECISORES` = ifelse(grepl(cargos_dm, `CARGO B2B`), yes = "MATCH", no = NA),
             `MATCHING BLACKLIST DE AREAS` = ifelse(grepl(blacklist, `CARGO B2B`), yes = "MATCH",no = NA),
             `MATCHING AREAS DE IT` = ifelse(grepl(IT_Keywords, `CARGO B2B`), yes = "MATCH",no = ifelse(`CARGO B2B` %in% isolados, yes = "MATCH", no = NA)))
    
    ITDM
    
  })
  
  ### Trata Left JoineR
  Left_JoineR <- reactive({
    
    esq <- base_esquerda()
    dir <- base_direita()
    
    left_JoineR <- left_join(esq, dir, by = input$colunas_join)
    
    left_JoineR
    
  })
  
  ### PRÉ-VISUALIZAÇÕES
  ### Pré-visualização dos Dados Cadastrais do DD
  output$Dados_Cadastrais <- DT::renderDataTable(datatable(Dados_Cadastrais(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização dos Sócios do DD
  output$Socios <- DT::renderDataTable(datatable(Socios(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização dos Dados Cadastrais do CDDP
  output$Dados_Cadastrais_CDDP <- DT::renderDataTable(datatable(Dados_Cadastrais_CDDP(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização dos Contatos do CDDP
  output$Contatos_CDDP <- DT::renderDataTable(datatable(contatos_CDDP(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização dos Contatos LinkedIn do CDDP
  output$contatos_LinkedIn_CDDP <- DT::renderDataTable(datatable(contatos_linkedin_CDDP(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização das empresas LinkedIn do CDDP
  output$empresas_LinkedIn_CDDP <- DT::renderDataTable(datatable(empresas_linkedin_CDDP(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização dos Dados Cadastrais BR2 do CDDP
  output$BR2_Dados_Cadastrais_CDDP <- DT::renderDataTable(datatable(BR2_Dados_Cadastrais(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização dos Sócios BR2 do CDDP
  output$BR2_Socios_CDDP <- DT::renderDataTable(datatable(base_BR2_Socios_CDDP(), options = list(pageLength = 1000, lengthChange = FALSE, paging = FALSE)))
  
  ### Pré-visualização dos Contatos do Apollo
  output$Contatos_Apollo <- DT::renderDataTable(datatable(Contatos_Apollo()))
  
  ### Pré-visualização das Empresas do Apollo
  output$Empresas_Apollo <- DT::renderDataTable(datatable(Empresas_Apollo()))
  
  ### Pré-visualização das Tecnologias Intricately
  output$Intricately <- DT::renderDataTable(datatable(Intricately()))
  
  ### Pré-visualização dos Contatos ITDM
  output$ITDM <- DT::renderDataTable(datatable(ITDM()))
  
  ### Pré-visualização do Left JoineR
  output$Left_JoineR <- DT::renderDataTable(datatable(Left_JoineR()))
  
  ### DOWNLOADS
  ### Download do arquivo tratado do DD
  output$Download_DD <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_", input$base_DD)
    },
    
    content = function(file) {
      
      #write_xlsx(list('Dados Cadastrais - DB - Cortex' = Dados_Cadastrais(), 'Sócios - DB - Cortex' = Socios()), col_names = TRUE, format_headers = FALSE)
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Dados Cadastrais - Cortex")
      openxlsx::writeData(wb = wb, sheet = "Dados Cadastrais - Cortex", x = Dados_Cadastrais())
      openxlsx::addWorksheet(wb = wb, sheetName = "Sócios - Cortex")
      openxlsx::writeData(wb = wb, sheet = "Sócios - Cortex", x = Socios())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download dos Dados Cadastrais tratados do CDDP
  output$Download_dados_cadastrais_CDDP <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_Dados_Cadastrais_CDDP.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Dados Cadastrais")
      openxlsx::writeData(wb = wb, sheet = "Dados Cadastrais", x = Dados_Cadastrais_CDDP())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download dos contatos tratados do CDDP
  output$Download_contatos_CDDP <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_Contatos_CDDP.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Contatos Apollo")
      openxlsx::writeData(wb = wb, sheet = "Contatos Apollo", x = contatos_CDDP())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download dos Contatos Linkedin tratados do CDDP
  output$Download_linkedin_CDDP <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_LinkedIn_CDDP.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Contatos LinkedIn")
      openxlsx::writeData(wb = wb, sheet = "Contatos LinkedIn", x = contatos_linkedin_CDDP())
      openxlsx::addWorksheet(wb = wb, sheetName = "Empresas LinkedIn")
      openxlsx::writeData(wb = wb, sheet = "Empresas LinkedIn", x = empresas_linkedin_CDDP())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download do arquivo BR2 tratados do CDDP
  output$Download_BR2_CDDP <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_BR2_CDDP.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Dados Cadastrais")
      openxlsx::writeData(wb = wb, sheet = "Dados Cadastrais", x = BR2_Dados_Cadastrais())
      openxlsx::addWorksheet(wb = wb, sheetName = "Sócios")
      openxlsx::writeData(wb = wb, sheet = "Sócios", x = base_BR2_Socios_CDDP())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download dos contatos tratados do Apollo
  output$Download_contatos_Apollo <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_Contatos_Apollo.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Contatos Apollo")
      openxlsx::writeData(wb = wb, sheet = "Contatos Apollo", x = Contatos_Apollo())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download das empresas tratadas do Apollo
  output$Download_empresas_Apollo <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_Empresas_Apollo.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Empresas Apollo")
      openxlsx::writeData(wb = wb, sheet = "Empresas Apollo", x = Empresas_Apollo())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download das Tecnologias tratadas do Intricately
  output$Download_Intricately <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_Intricately.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Intricately")
      openxlsx::writeData(wb = wb, sheet = "Intricately", x = Intricately())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download dos contatos com Match de ITDM
  output$Download_ITDM <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_Contatos_ITDM.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Contatos ITDM")
      openxlsx::writeData(wb = wb, sheet = "Contatos ITDM", x = ITDM())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
  ### Download do Left JoineR
  output$Download_Left_JoineR <- {downloadHandler(
    
    filename = function() {
      paste0("SCRIPT_Left_JoineR.xlsx")
    },
    
    content = function(file) {
      
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb = wb, sheetName = "Left_JoineR")
      openxlsx::writeData(wb = wb, sheet = "Left_JoineR", x = Left_JoineR())
      
      openxlsx::saveWorkbook(wb = wb, file = file)
    }
  )}
  
}
options(shiny.maxRequestSize = 200*1024^2)

shinyApp(ui, server)

#shinyShortcut(shinyDirectory = getwd(), OS = "windows",
#gitIgnore = FALSE)

#options(shiny.fullstacktrace = TRUE)
#options(shiny.reactlog = TRUE)
#app <- shinyApp(ui, server)
#shiny::runApp(app, display.mode="showcase")