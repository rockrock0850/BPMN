<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ page import="java.util.Date"%>

<c:set var='now' value='<%=new Date()%>' />
<c:set var="contextPath" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" />
<title>Hello World</title>

<!-- required modeler styles -->
<link rel="stylesheet"
	href="${contextPath}/static/thirdParty/bpmn/7.2.1/css/bpmn.css?v=${now}">
<link rel="stylesheet"
	href="${contextPath}/static/thirdParty/bpmn/7.2.1/css/diagram-js.css?v=${now}">
<link rel="stylesheet"
	href="${contextPath}/static/thirdParty/custom.css?v=${now}">

<!-- needed for this example only -->
<script src="${contextPath}/static/thirdParty/jquery/3.3.1/jquery.js?v=${now}"></script>

<!-- modeler distro -->
<%-- <script src="${contextPath}/static/thirdParty/commonJS/common.js?v=${now}"></script> --%>
<%-- <script src="${contextPath}/static/thirdParty/bpmn-panel/0.34.0/js/PropertiesPanel.js?v=${now}"></script> --%>
<script src="${contextPath}/static/thirdParty/bpmn/7.2.1/bpmn-modeler.development.js?v=${now}"></script>

<%-- <script src="${contextPath}/static/thirdParty/CustomContextPad.js?v=${now}"></script> --%>

<!-- example styles -->
<style>
html, body {
	height: 100%;
	padding: 0;
	margin: 0;
}

#canvas {
	height: 100%;
	padding: 0 10% 0 10%;
	margin: 0;
}

.diagram-note {
	background-color: rgba(66, 180, 21, 0.7);
	color: White;
	border-radius: 5px;
	font-family: Arial;
	font-size: 12px;
	padding: 5px;
	min-height: 16px;
	width: 50px;
	text-align: center;
}

.needs-discussion:not (.djs-connection ) .djs-visual>:nth-child(1) {
	stroke: rgba(66, 180, 21, 0.7) !important; /* color elements as red */
}

#save-button {
	position: fixed;
	bottom: 20px;
	left: 20px;
}

#deploy-button {
	position: fixed;
	bottom: 20px;
	left: 150px;
}
</style>
</head>
<body>
	<div id="canvas"></div>
	<div id="properties"></div>

	<button id="save-button">print to console</button>
	<button id="deploy-button">deploy diagram</button>

	<script>//# sourceURL=index.js
		var bpmnModeler = new BpmnJS({
			container : '#canvas',
			keyboard : {
				bindTo : window
			}
		});

		async function deployDiagram() {
			let form = new FormData();
			let modeling = bpmnModeler.get('modeling');
			let $process = $('g[data-element-id^="Process"]');
			let root = bpmnModeler.get('elementRegistry').
							get($process.attr('data-element-id'));

			form.append('deployment-name', 'Test Camunda Modeler');
			form.append('deployment-source', 'Camunda Modeler');
			form.append('deploy-changed-only', 'true');
			form.append('tenant-id', '0001');

			$.each(root.children, function (i, e) {
				if (e.type === "bpmn:Process") {
					modeling.updateProperties(e, {
						efsDelegat : 'com.ebizprise.bpmn.io.ProcessRequestDelegate'
					});
				}
				if (e.type === "bpmn:ServiceTask") {
					modeling.updateProperties(e, {
						efsDelegat : 'com.ebizprise.bpmn.io.ProcessRequestDelegate'
					});
				}
			});

			saveDiagram(function(err, result) {
				if (err) {
					console.log(err);
					return;
				}

				result.xml = result.xml.replace(/efsDelegat/g, "camunda:class");
				result.xml = result.xml.replace(/efsDelegat/g, "bpmn:definitions");
				
// 				const diagramName = root.id;
				const diagramName = 'Test Deployment.bpmn';
				const blob = new Blob([result.xml], {type : 'text/xml'});

				form.append(diagramName, blob, diagramName);
				
				var options = {
						url: '${contextPath}/engine-rest/deployment/create',
						data: form,
						processData: false,
						contentType: false,
						type: 'post',
						success: function (response) {
							console.log(response);
						},
						error: function (xhr) {
							console.log(xhr);
						},
						complete: function () {
						}
					};
					
				$.ajax(options);
			});
		}

		function isSequenceFlow(type) {
			// 判断是否是线
			return type === 'bpmn:SequenceFlow'
		}

		function isInvalid(param) {
			// 判断是否是无效的值
			return param === null || param === undefined || param === '';
		}

		function getShape(id) {
			var elementRegistry = bpmnModeler.get('elementRegistry')
			return elementRegistry.get(id);
		}

		function elementChanged(e) {
			var shape = getShape(e.element.id);
			console.log(shape);
			if (!shape) {
				// 若是shape为null则表示删除, 无论是shape还是connect删除都调用此处
				console.log('无效的shape');
				// 上面已经用 shape.removed 检测了shape的删除, 要是删除shape的话这里还会被再触发一次
				console.log('删除了shape和connect');
				return;
			}

			if (!isInvalid(shape.type)) {
				if (isSequenceFlow(shape.type)) {
					console.log('改变了线');
				}
			}
		}

		async function saveSVG(done) {
			// 把传入的done再传给bpmn原型的saveSVG函数调用
			try {
				const result = await
				bpmnModeler.saveSVG({
					format : true
				});
				done(null, result);
			} catch (err) {
				done(err, null);
			}
		}

		// 当图发生改变的时候会调用这个函数，这个data就是图的xml
		function setEncoded(link, name, data) {
			// 把xml转换为URI，下载要用到的
			const encodedData = encodeURIComponent(data);
			// 下载图的具体操作,改变a的属性，className令a标签可点击，href令能下载，download是下载的文件的名字
			//   console.log(link, name, data)
			let xmlFile = new File([
				data
			], 'test.bpmn');
			if (data) {
				link.className = 'active';
				link.href = 'data:application/bpmn20-xml;charset=UTF-8,' + encodedData;
				link.download = name;
			}
		}

		// 下载为bpmn格式,done是个函数，调用的时候传入的
		async function saveDiagram(done) {
			// 把传入的done再传给bpmn原型的saveXML函数调用
			try {
				const result = await
				bpmnModeler.saveXML({
					format : true
				});
				done(null, result);
			} catch (err) {
				done(err, null);
			}
		}

		function addBpmnListener() {
			// 获取a标签dom节点
			// 给图绑定事件，当图有发生改变就会触发这个事件
			bpmnModeler.on('commandStack.changed', function() {
				saveSVG(function(err, svg) {
					setEncoded({}, 'diagram.svg', err ? null : svg);
				});
				saveDiagram(function(err, xml) {
					setEncoded({}, 'diagram.bpmn', err ? null : xml);
				});
			})
		}

		function addModelerListener() {
			// 监听 modeler
			// 'shape.removed', 'connect.end', 'connect.move'
			const events = [
					'shape.added', 'shape.move.end', 'shape.removed'
			];
			events.forEach(function(event) {
				bpmnModeler.on(event, function(e) {
					var elementRegistry = bpmnModeler.get('elementRegistry');
					var shape = e.element ? elementRegistry.get(e.element.id) : e.shape;
					// console.log(shape)
					if (event === 'shape.added') {
						console.log('新增了shape');
					} else if (event === 'shape.move.end') {
						console.log('移动了shape');
					} else if (event === 'shape.removed') {
						console.log('删除了shape');
					}
				})
			})
		}

		function addEventBusListener() {
			// 监听 element
			const eventBus = bpmnModeler.get('eventBus');
			const modeling = bpmnModeler.get('modeling');
			const elementRegistry = bpmnModeler.get('elementRegistry');
			const eventTypes = [
					'element.click', 'element.changed'
			];
			eventTypes.forEach(function(eventType) {
				eventBus.on(eventType, function(e) {
					console.log(e)
					if (!e || e.element.type == 'bpmn:Process')
						return;

					if (eventType === 'element.changed') {
						elementChanged(e);
					} else if (eventType === 'element.click') {
						console.log('点击了element');
						var shape = e.element ? elementRegistry.get(e.element.id) : e.shape;
						if (shape.type === 'bpmn:StartEvent') {
							modeling.updateProperties(shape, {
								name : '我是修改后的虚线节点',
								isInterrupting : false,
								efsDelegat : '我是自定义的text属性'
							})
						}
					}
				})
			})
		}

		/**
		 * Save diagram contents and print them to the console.
		 */
		async function exportDiagram() {
			try {
				var result = await
				bpmnModeler.saveXML({
					format : true
				});
				console.log(result.xml);
			} catch (err) {
				alert('could not save BPMN 2.0 diagram', err);
			}
		}

		/**
		 * Open diagram in our modeler instance.
		 *
		 * @param {String} bpmnXML diagram to display
		 */
		async function openDiagram(bpmnXML) {
			// import diagram
			try {
				var result = await
				bpmnModeler.importXML(bpmnXML);
				if (result) {
					// access modeler components
					var canvas = bpmnModeler.get('canvas');
					var overlays = bpmnModeler.get('overlays');

					// zoom to fit full viewport
					canvas.zoom('fit-viewport');

					/* attach an overlay to a node
					overlays.add('SCAN_OK', 'note', {
						position : {
							bottom : 0,
							right : 0
						},
						html : '<div class="diagram-note">Mixed up the labels?</div>'
					});*/

					/* add marker
					canvas.addMarker('SCAN_OK', 'needs-discussion');*/
				}
			} catch (err) {
				return console.error('could not import BPMN 2.0 diagram', err);
			}
		}

		addBpmnListener();
		addModelerListener();
		addEventBusListener();

		// load external diagram file via AJAX and open it
		$.get('${contextPath}/static/testBpmn.bpmn', openDiagram, 'text');

		// wire save button
		$('#save-button').click(exportDiagram);
		$('#deploy-button').click(deployDiagram);
	</script>
</body>
</html>
