package test

import (
	"testing"
	"fmt"
	"strings"
	"os"
	helper "github.com/cloudposse/test-helpers/pkg/atmos/component-helper"
	// "github.com/cloudposse/test-helpers/pkg/atmos"
	awsTerratest "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/modules/random"
)

type ComponentSuite struct {
	helper.TestSuite

	githubOrg string
	githubToken string
	randomID string
	awsRegion string
}

func (s *ComponentSuite) TestBasic() {
	const component = "eks/argocd/basic"
	const stack = "default-test"
	const awsRegion = "us-east-2"

	randomID := strings.ToLower(random.UniqueId())
	namespace := fmt.Sprintf("argocd-%s", randomID)

	secretPath := fmt.Sprintf("/argocd/%s/github/api_key", s.randomID)
	defer func() {
		awsTerratest.DeleteParameter(s.T(), awsRegion, secretPath)
	}()
	awsTerratest.PutParameter(s.T(), s.awsRegion, secretPath, "Github API Key", s.githubToken)

	inputs := map[string]interface{}{
		"kubernetes_namespace": namespace,
		"ssm_github_api_key": secretPath,
	}

	defer s.DestroyAtmosComponent(s.T(), component, stack, &inputs)
	options, _ := s.DeployAtmosComponent(s.T(), component, stack, &inputs)
	assert.NotNil(s.T(), options)

	options, _ = s.DeployAtmosComponent(s.T(), component, stack, &inputs)
	assert.NotNil(s.T(), options)

	// s.DriftTest(component, stack, &inputs)
}

func (s *ComponentSuite) TestEnabledFlag() {
	const component = "eks/argocd/disabled"
	const stack = "default-test"
	s.VerifyEnabledFlag(component, stack, nil)
}

func (s *ComponentSuite) SetupSuite() {
	s.TestSuite.InitConfig()
	s.TestSuite.Config.ComponentDestDir = "components/terraform/eks/argocd"

	s.githubOrg = "cloudposse-tests"
	s.githubToken = os.Getenv("GITHUB_TOKEN")
	s.randomID = strings.ToLower(random.UniqueId())
	s.awsRegion = "us-east-2"

	if !s.Config.SkipDeployDependencies {
		deployKeyPath := fmt.Sprintf("/argocd/deploy_keys/%s/%s", s.randomID, "%s")
		repoName := fmt.Sprintf("argocd-github-repo-%s", s.randomID)
		secretPath := fmt.Sprintf("/argocd/%s/github/api_key", s.randomID)
		awsTerratest.PutParameter(s.T(), s.awsRegion, secretPath, "Github API Key", s.githubToken)

		inputs := map[string]interface{}{
			"ssm_github_deploy_key_format": deployKeyPath,
			"ssm_github_api_key": secretPath,
			"name": repoName,
			"github_organization": s.githubOrg,
		}
		s.AddDependency(s.T(), "argocd-github-repo", "default-test", &inputs)
	}

	s.TestSuite.SetupSuite()
}

func (s *ComponentSuite) TearDownSuite() {
	s.TestSuite.TearDownSuite()
	if !s.Config.SkipDestroyDependencies {
		secretPath := fmt.Sprintf("/argocd/%s/github/api_key", s.randomID)
		awsTerratest.DeleteParameter(s.T(), s.awsRegion, secretPath)
	}
}

func TestRunSuite(t *testing.T) {
	suite := new(ComponentSuite)
	suite.AddDependency(t, "vpc", "default-test", nil)
	suite.AddDependency(t, "eks/cluster", "default-test", nil)

	subdomain := strings.ToLower(random.UniqueId())
	inputs := map[string]interface{}{
		"zone_config": []map[string]interface{}{
			{
				"subdomain": subdomain,
				"zone_name": "components.cptest.test-automation.app",
			},
		},
	}
	suite.AddDependency(t, "dns-delegated", "default-test", &inputs)
	helper.Run(t, suite)
}
