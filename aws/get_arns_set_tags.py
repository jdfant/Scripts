#!/usr/bin/env python3
"""
Discover resources not tagged with specific key
then add tag key along with tag value
"""

import boto3

TAG_KEY = "ENTER_TAG"
TAG_VALUE = "ENTER_TAG_VALUE"


def get_tag_resources():
    """
    Discover resource ARNs
    """
    boto3.Session("get_resources")
    client = boto3.client("resourcegroupstaggingapi")
    paginator = client.get_paginator("get_resources")

    page_iterator = paginator.paginate(
        ResourceTypeFilters=[
            "acm:certificate",
            "autoscaling:autoscalinggroup",
            "cloudformation:stack",
            "codebuild:project",
            "ec2:customergateway",
            "dynamodb:table",
            "ec2:instance",
            "ec2:internetgateway",
            "ec2:networkacl",
            "ec2:networkinterface",
            "ec2:routetable",
            "ec2:securitygroup",
            "ec2:subnet",
            "ec2:volume",
            "ec2:vpc",
            "ec2:vpnconnection",
            "ec2:vpngateway",
            "elasticloadbalancing:loadbalancer",
            "rds:dbinstance",
            "rds:dbsecuritygroup",
            "rds:dbsnapshot",
            "rds:dbsubnetgroup",
            "rds:eventsubscription",
            "redshift:cluster",
            "redshift:clusterparametergroup",
            "redshift:clustersecuritygroup",
            "redshift:clustersnapshot",
            "redshift:clustersubnetgroup",
            "s3:bucket",
        ],
    )

    filtered_iterator = page_iterator.search(
        "ResourceTagMappingList[?!not_null(Tags[?Key==`TAG_KEY`])]"
    )

    for tags in filtered_iterator:
        results = tags.items()
        arns = list(results)[0]

        try:
            client.tag_resources(
                ResourceARNList=[(arns[1])], Tags={(TAG_KEY): (TAG_VALUE)}
            )
            print("Resources tagged:", end="\n")
            print(str(arns[1]))

        except BaseException:
            print("Error!")


def main():
    """Make it go"""
    get_tag_resources()


if __name__ == "__main__":
    main()
