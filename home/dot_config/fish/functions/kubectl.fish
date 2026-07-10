function kubectl --wraps=kubectl
    if type -q kubecolor
        command kubecolor $argv
    else
        command kubectl $argv
    end
end
