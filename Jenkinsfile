#!bash
pipeline{
   agent{
      label 'skopeo'
   }
   environment {
      appName = "test-service"
      buildconf = "false"
      DEV_NAMESPACE = "bookstore-dev"
      DEV_API_SERVER = "https://api.cluster-gbtvh.sandbox942.opentlc.com:6443"
      templatePath = "/tmp/workspace/cicd/dev"
   }
   stages {
      stage('Common Lib checkout') {
        steps {
           git branch: 'main',
           url: 'https://github.com/sree77hari/test-service.git'
          }
      }
      stage('Deploy Template Dev') {
	 steps {
	    script {
	       try {
		  openshift.withCluster(){
		     openshift.withProject("${env.PROJECT}"){
			echo "Using project: ${openshift.project()}"
			echo "${env.PROJECT}"
			echo "${appName}"
			if(!openshift.selector("svc",[template:"${appName}"]).exists() || !openshift.selector("dc",[template:"${appName}"]).exists() || !openshift.selector("route",[template:"${appName}"]).exists()){

			    openshift.newApp(templatePath/template.yaml)
			}
 		     }
		  }
	       }
	       catch(e){
		  print e.getMessage()
		  echo "This stage has an exception that can be ignored."
	       }
	    }
	 }
      }
      stage('Deploy Template in DEV Namespace') {
        steps{
           script {
             try {
                withCredentials([usernamePassword(credentialsId: 'dev-ocp-credentials', passwordVariable: 'DEV_OCP_PASSWD', usernameVariable: 'DEV_OCP_USER')]) {
                  echo "Using AppName: ${appName}"
                  sh('oc login -u $DEV_OCP_USER -p $DEV_OCP_PASSWD ${DEV_API_SERVER} -n ${DEV_NAMESPACE} --insecure-skip-tls-verify=true')
                  sh('ls')
                  sh('pwd')
                  buildconf = sh(script: 'oc get bc ${appName} >> /dev/null 2>&1 && echo "true" || echo "false"', returnStdout: true)
                  buildconf = buildconf.trim()
                  echo "BuildConfig status contains: '${buildconf}'"

                  if(buildconf == 'false') {
                    sh "oc new-app ${templatePath/template.yaml} --as-deployment-config -n ${DEV_NAMESPACE}"
                  } else {
                    echo "Template is already exist. Hence, skipping this stage."
                  }
                }
              } catch(e) {
                print e.getMessage()
                error "${DEV_NAMESPACE} stage having some issue so this stage can be ignored. Please check logs for more details."
              }
            }
          }
        }
        stage('Deploy Image Build to Dev Namespace') {
          steps {
            script {
              try {
                timeout(time: 180, unit: 'SECONDS') {
                  withCredentials([usernamePassword(credentialsId: 'dev-ocp-credentials', passwordVariable: 'DEV_OCP_PASSWD', usernameVariable: 'DEV_OCP_USER')]) {
                    sh('oc login -u $DEV_OCP_USER -p $DEV_OCP_PASSWD ${DEV_API_SERVER} -n ${DEV_NAMESPACE} --insecure-skip-tls-verify=true')
                    sh "oc start-build ${appName}"
                    echo "Build ${appName} deployed successfully in ${DEV_NAMESPACE} namespace"
                  }
                }
              } catch(e) {
                print e.getMessage()
                error "Build not successful"
              }
            }
          }
        }
        stage('Tag Image in Development Project') {
          steps {
            script {
              withCredentials([usernamePassword(credentialsId: 'dev-ocp-credentials', passwordVariable: 'DEV_OCP_PASSWD', usernameVariable: 'DEV_OCP_USER')]) {
                sh('oc login -u $DEV_OCP_USER -p $DEV_OCP_PASSWD ${DEV_API_SERVER} -n ${DEV_NAMESPACE} --insecure-skip-tls-verify=true')
                sh "oc tag ${DEV_NAMESPACE}/${appName}:latest ${DEV_NAMESPACE}/${appName}:${env.BUILD_NUMBER} -n ${DEV_NAMESPACE}"
              }
            }
          }
        }
     }
  }
