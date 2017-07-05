# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git mvn ssh-agent gpg-agent)

# User configuration

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export MAVEN_HOME=/usr/share/apache-maven-3.5.0/bin
export GOROOT=/usr/share/go
export GOPATH=/home/james/workspace/golang
export PATH=${JAVA_HOME}/bin:${MAVEN_HOME}:${GOROOT}/bin:${PATH}

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

DEFAULT_USER="james"

# Aliases
alias pbcopy="xclip -selection clipboard"

APP_OPTS=${HOME}/.dockerapps

function createAppAliases() {
  if [[ -f ${APP_OPTS} ]]; then
    for APP_NAME in $(cat ${APP_OPTS} | jq -r ".apps[].name")
    do
      alias ${APP_NAME}="createOrStartContainer ${APP_NAME} $@"
    done
  fi
}

function createOrStartContainer() {
  local APP=$1
  local APP_ARGS=$2
  local IMAGE=$(cat ${APP_OPTS} | jq -r ".apps[] | select(.name == \"${APP}\").image")
  local ARGS="$(cat ${APP_OPTS} | jq -r ".apps[] | select(.name == \"${APP}\").args")"
  local DAEMONIZE="$(cat ${APP_OPTS} | jq -r ".apps[] | select(.name == \"${APP}\").daemonize")"
  local AUTOREMOVE="$(cat ${APP_OPTS} | jq -r ".apps[] | select(.name == \"${APP}\").autoremove")"
  local PULL="$(cat ${APP_OPTS} | jq -r ".apps[] | select(.name == \"${APP}\").pull")"
  local CMD="$(cat ${APP_OPTS} | jq -r ".apps[] | select(.name == \"${APP}\").command")"
  local DOCKER_ARGS=""
  local EXTRA_ARGS="-it"
  local CREATED="false"

  if [[ ! -z "${IMAGE}" ]]; then
    [ ! -f /var/run/docker.pid ] && return

    local CONTAINER_INFO="$(sudo docker inspect --format '{{.Name}}:{{.State.Running}}' ${APP})"
    local NAME="$(echo ${CONTAINER_INFO} | cut -f1 -d:)"
    local RUNNING="$(echo ${CONTAINER_INFO} | cut -f2 -d:)"

    if [[ "${NAME}" == "/${APP}" ]] && [[ "${RUNNING}" == "false" ]]; then
      if [[ "${PULL}" == "false" ]]; then
        sudo docker start ${APP}
        CREATED="true"
      else
        sudo docker rm -f ${APP}
      fi
    elif [[ "${NAME}" == "/${APP}" ]] && [[ "${RUNNING}" == "true" ]]; then
      CREATED="true"
    fi

    if [[ "${PULL}" == "true" ]]; then
      sudo docker pull "${IMAGE}"
    fi

    if [[ "${CREATED}" == "false" ]]; then
      if [[ "${DAEMONIZE}" == "null" || ( ! -z "${DAEMONIZE}" && "${DAEMONIZE}" == "true") ]]; then
        EXTRA_ARGS="${EXTRA_ARGS} -d"
      else
        if [[ "${AUTOREMOVE}" != "null" ]] && [[ "${AUTOREMOVE}" == "true" ]]; then
          EXTRA_ARGS="${EXTRA_ARGS} --rm"
        fi
      fi

      if [[ "${ARGS}" != "null" ]]; then
        DOCKER_ARGS="${ARGS}"
      fi

      eval "sudo docker run --name ${APP} ${DOCKER_ARGS} ${EXTRA_ARGS} ${IMAGE} ${CMD} ${APP_ARGS}"
    fi
  else
    echo "${APP} is not configured"
  fi
}

createAppAliases


